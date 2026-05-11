# Runit Service Testing Framework

Lightweight service-to-service testing framework using runit supervision within the nix-build sandbox.

## Overview

This framework enables testing of service interactions using runit as a service supervisor, running entirely within nix-build's private network namespace. Unlike `ekaosTests` which use QEMU+systemd, these tests are:

- **Faster**: ~1-5s startup vs 10-30s boot time
- **Lighter**: 10-50 MB memory vs 512+ MB
- **Simpler**: No kernel boot, VM, or special features required
- **Pure**: Works in standard nix-build sandbox (no `__noChroot` needed)

## Architecture

```
nix-build sandbox
├─ Private network namespace (127.0.0.1)
├─ runsvdir (service supervisor)
│  ├─ service1/ (runit service directory)
│  ├─ service2/
│  └─ service3/
└─ Test script (validates service interactions)
```

**Key insight**: The nix sandbox's private network namespace provides automatic port isolation between builds, so multiple tests can run in parallel without conflicts.

## Components

### 1. runitTestHook

Setup hook that manages runit supervision during tests.

**Location**: `build-support/test-hooks/runit-test-hook/`

**Provides**:
- `runitTestStart` - Start runsvdir supervisor
- `runitTestStop` - Stop all services (automatic cleanup)
- `runitTestWaitPort <port>` - Wait for TCP port to be ready
- `runitTestWaitSocket <path>` - Wait for Unix socket
- `runitTestWaitService <name>` - Wait for service to be supervised
- `runitTestStatus` - Show status of all services

### 2. runitTests Library

Framework for defining service tests.

**Location**: `services/tests/runit-tests.nix`

**Functions**:
- `mkRunitTest` - Create a test with multiple services
- `mkServiceTest` - Quick test for a single service
- `mkInteractionTest` - Test client-server communication

### 3. Service Translation

Existing runit translation infrastructure (already in core-pkgs).

**Location**: `services/lib/runit-translate.nix`

Converts common service definitions to runit service directories.

## Usage

### Example 1: Simple HTTP Server Test

```nix
let
  runitTestsLib = pkgs.callPackage ./services/tests/runit-tests.nix {};
in
runitTestsLib.mkServiceTest "http-server" {
  command = "${pkgs.python3}/bin/python3";
  args = [ "-m" "http.server" "8080" "--bind" "127.0.0.1" ];
  user = "nobody";
} ''
  # Wait for server
  runitTestWaitPort 8080

  # Test it
  ${pkgs.curl}/bin/curl http://127.0.0.1:8080
''
```

### Example 2: Multi-Service Test

```nix
runitTestsLib.mkRunitTest {
  name = "backend-frontend-test";

  services = {
    backend = {
      command = "${pkgs.myBackend}/bin/backend";
      args = [ "--port" "8081" ];
      environment.DATABASE_URL = "sqlite::memory:";
    };

    frontend = {
      command = "${pkgs.myFrontend}/bin/frontend";
      args = [ "--backend" "http://127.0.0.1:8081" ];
    };
  };

  testScript = ''
    # Wait for services
    runitTestWaitPort 8081  # backend
    runitTestWaitPort 8080  # frontend

    # Test backend directly
    ${pkgs.curl}/bin/curl http://127.0.0.1:8081/api/health

    # Test frontend → backend flow
    ${pkgs.curl}/bin/curl http://127.0.0.1:8080
  '';
}
```

### Example 3: Service with Setup

```nix
runitTestsLib.mkServiceTest "http-with-data" {
  command = "${pkgs.python3}/bin/python3";
  args = [ "-m" "http.server" "8080" ];
  workingDirectory = "/tmp/webroot";

  preStart = ''
    mkdir -p /tmp/webroot
    echo "test data" > /tmp/webroot/test.txt
  '';
} ''
  runitTestWaitPort 8080

  ${pkgs.curl}/bin/curl http://127.0.0.1:8080/test.txt | \
    grep "test data"
''
```

## Building Tests

```bash
# Build single test
nix-build services/tests -A simple-http

# Build all tests
nix-build services/tests -A all

# Run test and see output
nix-build services/tests -A multi-service && cat result/logs/*
```

## Network Isolation

Each nix-build gets its own private network namespace with:
- ✅ Loopback interface (127.0.0.1)
- ✅ Services can bind to any port
- ✅ Multiple services in same build communicate freely
- ✅ Parallel builds don't conflict (separate namespaces)
- ✅ No external network access (isolated)

## Platform Support

### Linux
Fully supported. All features work.

### Darwin (macOS)
Supported with one additional requirement:

```nix
{
  __darwinAllowLocalNetworking = true;
}
```

The framework automatically sets this attribute.

## Comparison: runitTests vs ekaosTests

| Feature | runitTests | ekaosTests |
|---------|------------|------------|
| **Speed** | 1-5s | 10-30s |
| **Memory** | 10-50 MB | 512+ MB |
| **Parallelization** | Very High | Limited |
| **Requirements** | None | `kvm`, `nixos-test` |
| **Best for** | Service interaction tests | Full system tests |
| **Kernel** | Uses host | Boots own kernel |
| **Init** | runit | systemd |

## Dependencies

The framework requires these packages (ported from nixpkgs):

- **runit** (`pkgs/runit/`) - Service supervision
- **netcat-gnu** (`pkgs/netcat-gnu/`) - Port readiness checks

Both are now available in core-pkgs.

## Limitations

### What Works
- ✅ Multiple services in same test communicating via localhost
- ✅ TCP and Unix socket communication
- ✅ Environment variables and working directories
- ✅ preStart/postStop hooks
- ✅ Parallel test execution

### What Doesn't Work
- ❌ Communication between different test builds
- ❌ External network access (by design)
- ❌ Tests requiring specific kernel features
- ❌ Tests requiring real systemd

## Implementation Notes

### How It Works

1. **Service Build**: Service definitions are translated to runit service directories using `services/lib/runit-translate.nix`

2. **Test Setup**: The `preCheck` phase:
   - Creates `$TMPDIR/service/` directory
   - Symlinks service directories into it
   - Starts `runsvdir` in background
   - Waits for all services to be supervised

3. **Test Execution**: The `checkPhase` runs the test script with services running

4. **Cleanup**: The `postCheck` hook automatically stops runsvdir and all services

### Key Files

```
services/
├── tests/
│   ├── runit-tests.nix       # Test framework library
│   ├── default.nix            # Example tests
│   └── README.md              # This file
├── lib/
│   ├── runit-translate.nix    # Service → runit translation
│   └── runit-options.nix      # Runit-specific options
build-support/
└── test-hooks/
    └── runit-test-hook/
        ├── default.nix        # Hook package
        └── runit-test-hook.sh # Hook implementation
pkgs/
├── runit/                     # Runit package
└── netcat-gnu/                # Netcat package
```

## Future Enhancements

Possible improvements:
- Log aggregation and structured output
- Test timeout configuration
- Service dependency ordering
- Health check integration
- Performance metrics collection

## References

- Inspired by nixpkgs' `redisTestHook`, `postgresqlTestHook`
- Similar to ekaosTests but without VM overhead
- Uses nix sandbox network namespace (see: Nix manual § 15.1)
