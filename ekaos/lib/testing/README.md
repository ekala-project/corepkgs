# ekaosTest - Testing Framework for ekaos

ekaosTest is a testing framework for ekaos systems, inspired by nixosTest from nixpkgs. It provides infrastructure for writing automated tests of ekaos configurations using QEMU VMs and Python test scripts.

## Features

- **Single and Multi-VM Testing**: Define test VMs with complete ekaos configurations
- **Python Test Driver**: Write tests in Python with high-level test primitives
- **Systemd Integration**: Built-in support for waiting on systemd units and services
- **Network Testing**: Test inter-service communication (Phase 2, planned)
- **Automatic VM Management**: VMs are automatically built and started

## Quick Start

### Basic Test Example

```nix
# my-test.nix
{ pkgs, ... }:

{
  name = "simple-boot-test";

  meta = {
    description = "Test basic system boot";
    timeout = 300;
  };

  nodes = {
    machine = { config, pkgs, ... }: {
      boot.kernelPackages = pkgs.linuxPackages;
      virtualisation.enable = true;
    };
  };

  testScript = ''
    # Start the machine
    machine.start()

    # Wait for systemd to reach multi-user target
    machine.wait_for_unit("multi-user.target")

    # Run a command
    machine.succeed("echo 'Hello from ekaosTest'")

    # Shutdown
    machine.shutdown()
  '';
}
```

### Running Tests

```bash
# Build and run a test
nix-build -E '(import ./. {}).ekaosTest ./my-test.nix'

# Or using the test suite
nix-build ekaos/tests -A simple
```

## Test Structure

### Test Attributes

A test definition is a Nix attribute set with the following structure:

- **`name`** (string, required): Test name, used for derivation naming
- **`meta`** (attrset, optional): Test metadata
  - `description` (string): Test description
  - `timeout` (int): Test timeout in seconds (default: 3600)
  - `maintainers` (list): List of maintainers
- **`nodes`** (attrset, required): VM definitions
  - Each attribute defines a VM with an ekaos configuration
  - For single-VM tests, use `nodes.machine`
- **`defaults`** (attrset or function, optional): Configuration applied to all nodes
- **`testScript`** (string or function, required): Python test code

### Node Configuration

Each node is a complete ekaos system configuration:

```nix
nodes = {
  machine = { config, pkgs, lib, ... }: {
    # Required: kernel packages
    boot.kernelPackages = pkgs.linuxPackages;

    # Required: enable virtualisation
    virtualisation.enable = true;

    # Optional: VM configuration
    virtualisation.memorySize = 2048;
    virtualisation.cores = 2;
    virtualisation.diskSize = 8192;
  };
};
```

### Test Script

The test script is Python code with access to machine objects:

```python
# Start all machines
start_all()

# Or start individually
machine.start()

# Wait for systemd unit
machine.wait_for_unit("multi-user.target")

# Execute commands
output = machine.succeed("systemctl status")
machine.fail("false")  # Assert command fails

# Wait for network ports
machine.wait_for_open_port(80)

# Subtests for organization
with subtest("Boot"):
    machine.wait_for_unit("multi-user.target")

with subtest("Service"):
    machine.succeed("systemctl status myservice")
```

## Python Test Driver API

### Machine Class

Each node in your test becomes a `Machine` object with these methods:

#### Boot and Lifecycle

- **`start()`**: Start the VM
- **`shutdown()`**: Clean shutdown of the VM
- **`crash()`**: Force stop the VM
- **`wait_for_unit(unit, user=None, timeout=900)`**: Wait for systemd unit to be active
- **`wait_until_succeeds(command, timeout=900)`**: Retry command until it succeeds
- **`wait_until_fails(command, timeout=900)`**: Retry command until it fails

#### Command Execution

- **`succeed(command, timeout=900)`**: Execute command, assert exit code 0, return stdout
- **`fail(command, timeout=900)`**: Execute command, assert non-zero exit code
- **`execute(command, timeout=900)`**: Execute command, return (exit_code, stdout)

#### Network Testing

- **`wait_for_open_port(port, timeout=900)`**: Wait for TCP port to be listening
- **`wait_for_closed_port(port, timeout=900)`**: Wait for TCP port to be closed

#### Console Interaction

- **`send_key(key)`**: Send key to VM (e.g., "enter", "ctrl-alt-delete")
- **`wait_for_text(text, timeout=900)`**: Wait for text to appear on console
- **`wait_for_console_text(text, timeout=900)`**: Alias for wait_for_text

### Helper Functions

- **`start_all()`**: Start all machines in the test
- **`subtest(name)`**: Context manager for organizing test sections

```python
with subtest("Database initialization"):
    machine.succeed("initdb")
    machine.wait_for_open_port(5432)
```

## Test Examples

### Example 1: Service Testing

```nix
{
  name = "nginx-test";

  nodes.webserver = { pkgs, ... }: {
    boot.kernelPackages = pkgs.linuxPackages;
    virtualisation.enable = true;
  };

  testScript = ''
    webserver.start()
    webserver.wait_for_unit("nginx.service")
    webserver.wait_for_open_port(80)
    webserver.succeed("curl -f http://localhost/")
    webserver.shutdown()
  '';
}
```

### Example 2: Multi-Node Testing (Phase 2)

```nix
{
  name = "client-server-test";

  nodes = {
    server = { pkgs, ... }: {
      boot.kernelPackages = pkgs.linuxPackages;
      virtualisation.enable = true;
      # Server configuration
    };

    client = { pkgs, ... }: {
      boot.kernelPackages = pkgs.linuxPackages;
      virtualisation.enable = true;
      # Client configuration
    };
  };

  testScript = ''
    start_all()

    # Wait for server
    server.wait_for_unit("multi-user.target")
    server.wait_for_open_port(8080)

    # Test from client
    client.wait_for_unit("multi-user.target")
    client.succeed("curl -f http://server:8080/")
  '';
}
```

### Example 3: Using Defaults

```nix
{
  name = "cluster-test";

  defaults = { pkgs, ... }: {
    boot.kernelPackages = pkgs.linuxPackages;
    virtualisation.enable = true;
    virtualisation.memorySize = 1024;
  };

  nodes = {
    node1 = { ... }: { /* specific config */ };
    node2 = { ... }: { /* specific config */ };
    node3 = { ... }: { /* specific config */ };
  };

  testScript = ''
    start_all()
    # Test cluster functionality
  '';
}
```

## Architecture

### Module System

ekaosTest uses a module system to configure tests:

- **`nodes.nix`**: Builds ekaos systems for each test VM
- **`meta.nix`**: Test metadata and passthru attributes
- **`testScript.nix`**: Processes Python test scripts and generates machine objects
- **`driver.nix`**: Builds the test driver executable
- **`run.nix`**: Creates the test derivation

### Python Test Driver

Located in `ekaos/lib/test-driver/src/test_driver/`:

- **`machine.py`**: Machine class implementation with test primitives
- **`__init__.py`**: Driver entry point, machine registration
- **`logger.py`**: Logging utilities

### Public API

Exposed via `pkgs.ekaosTest`:

```nix
# In your Nix expressions
pkgs.ekaosTest {
  name = "my-test";
  nodes.machine = { ... };
  testScript = "...";
}

# Or with a file
pkgs.ekaosTest ./path/to/test.nix
```

## Test Suite

Example tests are provided in `ekaos/tests/`:

- **`simple.nix`**: Basic boot and shutdown test
- **`service.nix`**: Systemd service management test
- **`boot-process.nix`**: Boot stages and systemd targets test

Run tests:

```bash
# Single test
nix-build ekaos/tests -A simple

# All tests
nix-build ekaos/tests -A all
```

## Development Phases

### Phase 1 (MVP - Single VM) ✅ Complete

- Core module system
- Python test driver with basic primitives
- Single-VM testing support
- Example tests

### Phase 2 (Multi-VM) 🚧 Planned

- Network configuration module
- VDE virtual networking
- Multi-node primitives (wait_for_machine, etc.)
- Inter-VM communication tests

### Phase 3 (Polish) 📋 Future

- Advanced primitives (screenshot, OCR, GUI interaction)
- Interactive test debugging
- Comprehensive test suite
- Performance optimizations

## Current Limitations

⚠️ **Note**: The current implementation depends on nixpkgs' `make-disk-image.nix`, which requires `pkgs.vmTools`. This dependency is not yet available in core-pkgs. Alternative approaches being considered:

1. Implement a minimal disk image builder in core-pkgs
2. Use alternative VM testing approaches (direct kernel boot, initrd-based testing)
3. Port required vmTools functionality to core-pkgs

## Comparison with nixosTest

| Feature | nixosTest | ekaosTest |
|---------|-----------|-----------|
| Module system | ✅ | ✅ |
| Python driver | ✅ | ✅ |
| Single-VM tests | ✅ | ✅ |
| Multi-VM tests | ✅ | 🚧 Phase 2 |
| Network testing | ✅ | 🚧 Phase 2 |
| Interactive mode | ✅ | 📋 Phase 3 |
| GUI testing | ✅ | 📋 Phase 3 |

## Contributing

When adding new test primitives to the Machine class:

1. Add method to `ekaos/lib/test-driver/src/test_driver/machine.py`
2. Update this documentation
3. Add example test demonstrating the new primitive

## See Also

- nixosTest documentation: https://nixos.org/manual/nixos/stable/#sec-nixos-tests
- ekaos documentation: `ekaos/README.md`
- Example tests: `ekaos/tests/`
