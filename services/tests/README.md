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

### 1. runitTestDriver (Python)

Python test driver providing nixosTest-compatible API for writing test scripts.

**Location**: `services/tests/runit-test-driver/`

**Python API** (via `machine` object):
- `machine.execute(command, timeout)` - Run command, return (returncode, output)
- `machine.succeed(command, timeout)` - Run command, assert success
- `machine.fail(command, timeout)` - Run command, assert failure
- `machine.wait_for_open_port(port, addr="localhost", timeout=900)` - Wait for TCP port
- `machine.wait_until_succeeds(command, timeout=900)` - Retry until success
- `machine.wait_for_unit(service, timeout=900)` - Wait for runit service
- `machine.sv_status(service)` - Get service status
- `machine.sv_up(service)`, `machine.sv_down(service)` - Control services

**Test Organization**:
- `subtest(name)` - Context manager for test sections
- `log(message)` - Log messages with proper formatting
- Automatic colored output with success/failure indicators

### 2. runitTestHook

Setup hook that manages runit supervision during tests.

**Location**: `build-support/test-hooks/runit-test-hook/`

Automatically starts/stops runit services. Used internally by the framework.

### 3. runitTests Library

Framework for defining service tests.

**Location**: `services/tests/runit-tests.nix`

**Functions**:
- `mkRunitTest` - Create a test with multiple services
- `mkServiceTest` - Quick test for a single service
- `mkInteractionTest` - Test client-server communication

### 4. Service Translation

Existing runit translation infrastructure (already in core-pkgs).

**Location**: `services/lib/runit-translate.nix`

Converts common service definitions to runit service directories.

## Usage

All test scripts are written in **Python** using a nixosTest-compatible API. The `machine` object provides methods for interacting with services.

### Example 1: Simple HTTP Server Test

```nix
let
  runitTestsLib = pkgs.callPackage ./services/tests/runit-tests.nix {};
in
runitTestsLib.mkServiceTest "http-server" {
  command = "${pkgs.python3}/bin/python3";
  args = [ "-m" "http.server" "8080" "--bind" "127.0.0.1" ];
} ''
  # Wait for server (Python API)
  machine.wait_for_open_port(8080)
  log("Testing HTTP server...")

  # Make request and check response
  response = machine.succeed("curl -s http://127.0.0.1:8080")
  assert "Directory listing" in response
  log("HTTP server is working!")
''
```

### Example 2: Multi-Service Test with Subtests

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
    # Test backend with subtest context
    with subtest("backend startup"):
        machine.wait_for_open_port(8081)
        response = machine.succeed("curl -s http://127.0.0.1:8081/api/health")
        assert "ok" in response
        log("Backend OK")

    # Test frontend
    with subtest("frontend proxy"):
        machine.wait_for_open_port(8080)
        response = machine.succeed("curl -s http://127.0.0.1:8080")
        log("Frontend OK")
  '';
}
```

### Example 3: Service with Setup and Environment

```nix
runitTestsLib.mkServiceTest "http-with-data" {
  command = "${pkgs.python3}/bin/python3";
  args = [ "-m" "http.server" "8080" ];
  workingDirectory = "/tmp/webroot";

  environment.DATA_PATH = "/tmp/webroot";

  preStart = ''
    mkdir -p /tmp/webroot
    echo "test data" > /tmp/webroot/test.txt
  '';
} ''
  machine.wait_for_open_port(8080)
  log("Testing preStart hook...")

  response = machine.succeed("curl -s http://127.0.0.1:8080/test.txt")
  assert "test data" in response, f"Expected 'test data', got: {response}"
  log("preStart hook worked!")
''
```

### Example 4: Using wait_until_succeeds

```nix
testScript = ''
  # Wait for service to become healthy (with retries)
  machine.wait_until_succeeds(
      "curl -s http://127.0.0.1:8080/health | grep 'healthy'",
      timeout=60
  )

  # Test the service
  response = machine.succeed("curl -s http://127.0.0.1:8080/api/data")
  log(f"Got response: {response}")
'';
```

## Python API Reference

The test driver provides a `machine` object with the following methods:

### Command Execution

```python
# Execute command, return (returncode, output)
returncode, output = machine.execute("ls -la", timeout=30)

# Execute and assert success (raises exception on failure)
output = machine.succeed("curl http://localhost:8080")

# Execute and assert failure (raises exception on success)
output = machine.fail("curl http://nonexistent:9999")
```

### Waiting and Polling

```python
# Wait for TCP port to be open
machine.wait_for_open_port(8080, addr="localhost", timeout=900)

# Wait for command to succeed (retries with exponential backoff)
machine.wait_until_succeeds(
    "curl -s http://localhost:8080/health | grep 'ok'",
    timeout=60
)

# Wait for runit service to be running
machine.wait_for_unit("myservice", timeout=900)
```

### Service Control

```python
# Get service status (returns sv status output)
status = machine.sv_status("myservice")

# Start service
machine.sv_up("myservice")

# Stop service
machine.sv_down("myservice")
```

### Test Organization

```python
# Use subtests for hierarchical test organization
with subtest("service startup"):
    machine.wait_for_open_port(8080)
    log("Service is up")

with subtest("api functionality"):
    response = machine.succeed("curl http://localhost:8080/api")
    assert "data" in response

# Log messages (automatically formatted and colored)
log("Testing something important...")
```

### Assertions

```python
# Python assertions work as expected
response = machine.succeed("curl -s http://localhost:8080")
assert "expected" in response, f"Expected 'expected', got: {response}"

# Check service status
status = machine.sv_status("myservice")
assert "run:" in status, "Service is not running"
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
   - Copies service directories into it
   - Starts `runsvdir` in background
   - Waits for all services to be supervised

3. **Test Execution**: The `checkPhase`:
   - Writes the Python testScript to `/build/test-script.py`
   - Executes `python3 -m runit_test_driver --testscript /build/test-script.py`
   - Test driver provides `machine`, `subtest`, and `log` to test script
   - Test script runs with services already supervised

4. **Cleanup**: The `postCheck` hook automatically stops runsvdir and all services

### Key Files

```
services/
├── tests/
│   ├── runit-tests.nix            # Test framework library
│   ├── default.nix                 # Example tests
│   ├── README.md                   # This file
│   └── runit-test-driver/          # Python test driver
│       ├── default.nix             # Package definition
│       ├── setup.py                # Python package setup
│       └── src/runit_test_driver/
│           ├── __init__.py         # Module exports
│           ├── __main__.py         # CLI entry point
│           ├── driver.py           # Test driver (~150 lines)
│           ├── machine.py          # RunitMachine API (~400 lines)
│           └── logger.py           # Logging utilities (~70 lines)
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
