# mkDevShell - Development Shells with Services

> **Status**: Phase 1 Complete (Core Infrastructure)

Create development shells with running services using ekaos modules.

## Quick Start

Create a `shell.nix`:

```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkDevShell {
  modules = [
    {
      services.http-server = {
        enable = true;
        command = "${pkgs.python3}/bin/python3";
        args = [ "-m" "http.server" "8080" ];
        restartPolicy = "always";
      };
    }
  ];

  packages = [ pkgs.curl ];
}
```

Enter the shell:

```bash
nix-shell
# Services are configured and ready
# Use pc-up to start them (when process-compose is available)
```

## Features

✅ **Declarative Services**: Use familiar ekaos module syntax
✅ **Process-Compose Integration**: Services managed by industry-standard process-compose
✅ **Shell Utilities**: `pc-up`, `pc-down`, `pc-status`, `pc-logs`, etc.
✅ **Auto-configured**: Service config generated automatically

## Usage

### Define Services

Services are configured using ekaos modules with the same options as production systems:

```nix
pkgs.mkDevShell {
  modules = [
    {
      # Service configuration
      services.myservice = {
        enable = true;
        description = "My Development Service";

        command = "${pkgs.myapp}/bin/myapp";
        args = [ "--dev" ];

        workingDirectory = toString ./.;

        environment = {
          PORT = "3000";
          ENV = "development";
        };

        restartPolicy = "always";

        preStart = ''
          echo "Initializing..."
          mkdir -p ./data
        '';
      };
    }
  ];
}
```

### Shell Utilities

When you enter the shell, these utilities are available:

- **`pc-up`**: Start all services with TUI
- **`pc-down`**: Stop all services
- **`pc-status`**: Show service status
- **`pc-logs [service]`**: View service logs
- **`pc-restart [service]`**: Restart services
- **`pc-start <service>`**: Start specific service
- **`pc-stop <service>`**: Stop specific service
- **`pc-clean`**: Clean service data directories

### Environment Variables

- `PROCESS_COMPOSE_CONFIG`: Path to generated process-compose.yaml
- `DEV_DATA_DIR`: Service data directory (default: `./.dev/data`)
- `DEV_LOG_DIR`: Service log directory (default: `./.dev/logs`)

## Examples

### Simple HTTP Server

See `examples/simple.nix` for a single-service example:

```bash
cd dev-shell/examples
nix-shell simple.nix
pc-up  # Start the server
```

### Multi-Service with Dependencies

See `examples/multi-service.nix` for a complete example with:
- Backend API service (port 8081)
- Frontend web service (port 8080, depends on backend)
- Background worker (depends on backend)

```bash
cd dev-shell/examples
nix-shell multi-service.nix
pc-up  # Starts all services in dependency order
```

## Service Configuration Options

All ekaos common service options are supported:

- `enable`: Enable the service
- `description`: Human-readable description
- `command`: Main command to execute
- `args`: Command arguments
- `workingDirectory`: Working directory
- `environment`: Environment variables
- `restartPolicy`: When to restart (always, on-failure, never)
- `preStart`: Hook run before starting
- `postStart`: Hook run after starting (limited support)
- `postStop`: Hook run after stopping
- `after`: List of services that must start before this one
- `before`: List of services that must start after this one

## Phase 2 Features

✅ **process-compose Integration**: Full process-compose 1.94.0 support
✅ **Service Dependencies**: Use `after` and `before` options for ordering
✅ **Multi-service Support**: Run multiple interdependent services
✅ **Working Examples**: Both single and multi-service examples included

## Next Steps (Future Phases)

- **Phase 2**: Service lifecycle & dependencies
- **Phase 3**: Cross-platform support (macOS, WSL2)
- **Phase 4**: Common services library (PostgreSQL, Redis, etc.)
- **Phase 5**: Advanced features (profiles, secrets, hot-reload)

See `../devshell-services-plan.md` for the complete implementation plan.

## Architecture

```
mkDevShell { modules = [...] }
    ↓
ekaos Module Evaluation
    ↓
process-compose Translation
    ↓
Generated process-compose.yaml
    ↓
Development Shell + Utilities
```

## Files

- `default.nix`: mkDevShell function
- `lib/utilities.nix`: Shell utility scripts
- `examples/simple.nix`: Example usage
- `../services/lib/process-compose-translate.nix`: Translation layer

## Contributing

This is Phase 1 (MVP). Contributions welcome!

See the implementation plan for roadmap and future features.

## License

(Same as core-pkgs)
