# Cross-Service Interface Implementation

This directory contains the implementation of a unified service management interface that works across different service managers (systemd, launchd, runit, BSD rc.d).

## Status

**Phase 1 Complete**: Core infrastructure and systemd user service support working!

✅ Core module infrastructure
✅ Common service options (command, args, environment, user, lifecycle hooks, etc.)
✅ Systemd translation layer
✅ Systemd user service generation
✅ Working prototype with SQLite service

## Architecture

```
services/
├── lib/
│   ├── types.nix              # Custom types for service definitions
│   ├── options.nix            # Common service options
│   ├── systemd-options.nix    # Systemd-specific options
│   ├── systemd-translate.nix  # Common → systemd translation
│   └── service-module.nix     # Core module infrastructure
├── examples/
│   ├── simple-test.nix        # Minimal test service
│   ├── sqlite-simple.nix      # SQLite logger (working!)
│   └── sqlite-server.nix      # SQLite HTTP server
├── default.nix                # Main entry point
└── README.md                  # This file
```

## Usage

### Defining a Service

```nix
{ pkgs ? import ../. { } }:

let
  services = import ./services { inherit pkgs; };

  serviceConfig = {
    my-service = {
      enable = true;
      description = "My Example Service";

      command = "${pkgs.python3}/bin/python3";
      args = [ "-m" "http.server" "8080" ];

      environment = {
        PORT = "8080";
      };

      path = with pkgs; [ coreutils ];

      restartPolicy = "always";

      preStart = ''
        echo "Starting my service..."
      '';

      # Systemd-specific options
      systemd = {
        wantedBy = [ "default.target" ];
        serviceConfig = {
          PrivateTmp = true;
          NoNewPrivileges = true;
        };
      };
    };
  };
in
{
  systemdService = services.buildSystemdUserServices serviceConfig;
}
```

### Building and Installing

```bash
# Build the service file
nix-build -A systemdService

# Install to user systemd directory
cp result/my-service.service ~/.config/systemd/user/

# Reload and start
systemctl --user daemon-reload
systemctl --user start my-service
systemctl --user status my-service
```

## Example: SQLite Logger

A working example is available in `examples/sqlite-simple.nix`:

```bash
# Build
nix-build services/examples/sqlite-simple.nix -A systemdService

# Install
cp result/sqlite-logger.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user start sqlite-logger

# Check logs
journalctl --user -u sqlite-logger -f

# Query the database
sqlite3 ~/.local/share/sqlite-logger/log.db \
  "SELECT datetime(timestamp, 'localtime'), message FROM logs ORDER BY id DESC LIMIT 5;"
```

## Common Service Options

All service managers support these common options:

- `enable` - Whether to enable the service
- `description` - Human-readable description
- `command` - Main command to execute
- `args` - Command arguments
- `workingDirectory` - Working directory
- `user` / `group` - User/group context
- `environment` - Environment variables
- `path` - Packages to add to PATH
- `restartPolicy` - When to restart (always, on-failure, etc.)
- `preStart` / `postStart` / `postStop` - Lifecycle hooks

## Systemd-Specific Options

Under `systemd = { ... }`:

- `serviceConfig` - Raw [Service] section options
- `unitConfig` - Raw [Unit] section options
- `wants` / `requires` - Dependencies
- `after` / `before` - Ordering
- `wantedBy` - Installation targets

## Future Work

- [ ] Systemd system services (not just user services)
- [ ] Launchd support (macOS)
- [ ] Runit support
- [ ] BSD rc.d support (FreeBSD, OpenBSD, NetBSD, DragonFly)
- [ ] Validation and warnings for incompatible options
- [ ] Migration tooling from existing service definitions
- [ ] Integration with home-manager
- [ ] Socket activation support
- [ ] Timer/scheduling support

## Related Documentation

See `../cross-service-plan.md` for the full design document.

## Testing

Run the simple test to verify basic functionality:

```bash
nix-build services/examples/simple-test.nix -A systemdService
cat result/test-service.service
```

Expected output:
```
[Unit]
Description=Test Service

[Service]
Type=simple
ExecStart=/nix/store/.../echo hello world
Restart=on-failure

[Install]
WantedBy=default.target
```
