# Cross-Service Interface Implementation

This directory contains the implementation of a unified service management interface that works across different service managers (systemd, launchd, runit, BSD rc.d).

## Status

**Phase 2 Complete**: Launchd support added for macOS!

✅ Core module infrastructure
✅ Common service options (command, args, environment, user, lifecycle hooks, etc.)
✅ Systemd translation layer
✅ Systemd user service generation
✅ **Launchd translation layer**
✅ **Launchd user agent & daemon generation**
✅ **Cross-platform examples (systemd + launchd)**
✅ Working prototypes with SQLite service and HTTP server

## Architecture

```
services/
├── lib/
│   ├── types.nix              # Custom types for service definitions
│   ├── options.nix            # Common service options
│   ├── systemd-options.nix    # Systemd-specific options
│   ├── systemd-translate.nix  # Common → systemd translation
│   ├── launchd-options.nix    # Launchd-specific options (NEW!)
│   ├── launchd-translate.nix  # Common → launchd plist translation (NEW!)
│   └── service-module.nix     # Core module infrastructure
├── examples/
│   ├── simple-test.nix            # Minimal test service
│   ├── sqlite-simple.nix          # SQLite logger (systemd)
│   ├── sqlite-simple-launchd.nix  # SQLite logger (cross-platform) (NEW!)
│   ├── sqlite-server.nix          # SQLite HTTP server (systemd)
│   └── http-server-launchd.nix    # HTTP server (cross-platform) (NEW!)
├── tests/
│   └── launchd-test.nix       # Launchd test suite (NEW!)
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

      # Launchd-specific options (for macOS)
      launchd = {
        label = "com.example.my-service";
        runAtLoad = true;
        keepAlive = true;
        processType = "Background";
      };
    };
  };
in
{
  # Build for different platforms
  systemdService = services.buildSystemdUserServices serviceConfig;
  launchdUserAgent = services.buildLaunchdUserAgents serviceConfig;
  launchdDaemon = services.buildLaunchdDaemons serviceConfig;
}
```

### Building and Installing

#### Linux (systemd)

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

#### macOS (launchd)

```bash
# Build the user agent plist
nix-build -A launchdUserAgent

# Install to user LaunchAgents directory
cp result/my-service.plist ~/Library/LaunchAgents/

# Load and start
launchctl load ~/Library/LaunchAgents/my-service.plist
launchctl list | grep my-service

# Check status
launchctl list my-service

# View logs (check Console.app or):
log show --predicate 'process == "my-service"' --last 1h
```

For system-wide daemons (requires sudo):

```bash
# Build the daemon plist
nix-build -A launchdDaemon

# Install to system LaunchDaemons directory
sudo cp result/my-service.plist /Library/LaunchDaemons/

# Load and start
sudo launchctl load /Library/LaunchDaemons/my-service.plist
```

## Example: SQLite Logger

### Linux (systemd)

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

### macOS (launchd)

A cross-platform example is available in `examples/sqlite-simple-launchd.nix`:

```bash
# Build
nix-build services/examples/sqlite-simple-launchd.nix -A launchdUserAgent

# Install
cp result/sqlite-logger.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/sqlite-logger.plist

# Check status
launchctl list | grep sqlite-logger

# View logs in Console.app or:
log stream --predicate 'eventMessage contains "SQLite"' --level info

# Query the database
sqlite3 ~/.local/share/sqlite-logger/log.db \
  "SELECT datetime(timestamp, 'localtime'), message FROM logs ORDER BY id DESC LIMIT 5;"

# Stop and unload
launchctl unload ~/Library/LaunchAgents/sqlite-logger.plist
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

## Launchd-Specific Options (macOS)

Under `launchd = { ... }`:

### Launch Behavior
- `label` - Unique identifier (reverse DNS notation, e.g., "com.example.myservice")
- `runAtLoad` - Start immediately when loaded (at boot/login)
- `keepAlive` - Restart behavior (bool or conditions dict)

### Event-Driven Triggers
- `watchPaths` - Start when files change (list of paths)
- `queueDirectories` - Start when files appear in directories (batch processing)

### Scheduling
- `startInterval` - Periodic start interval in seconds
- `startCalendarInterval` - Start at specific times (hour, minute, day, weekday, month)

### Process Management
- `processType` - Priority class: "Standard", "Background", "Interactive", "Adaptive"
- `nice` - Process nice value (-20 to 20)

### Resource Limits
- `softResourceLimits` - Soft limits (NumberOfFiles, NumberOfProcesses, etc.)
- `hardResourceLimits` - Hard limits (same keys)

### I/O & Timeouts
- `standardInPath` - Path for stdin
- `exitTimeout` - Seconds to wait before SIGKILL (default: 20)

### Security
- `umask` - File creation mask (decimal)
- `sessionCreate` - Create new security session (for GUI apps)

### Advanced Options
- `enableTransactions` - Enable XPC transaction support
- `abandonProcessGroup` - Don't kill child processes on exit
- `extraConfig` - Raw plist passthrough for advanced features

## Platform Differences & Limitations

### Common Options Across All Platforms

These options work consistently on both systemd and launchd:
- `enable`, `description`, `command`, `args`
- `workingDirectory`, `user`, `group`
- `environment`, `path`
- `restartPolicy` (automatically translated)

### Platform-Specific Behaviors

**preStart hooks:**
- **systemd**: Runs as separate ExecStartPre unit
- **launchd**: Wrapped in shell script before main command

**postStart/postStop:**
- **systemd**: Full support via ExecStartPost/ExecStopPost
- **launchd**: Limited support (warnings issued, needs wrapper scripts)

**Restart policies:**
- `always` → systemd: `Restart=always`, launchd: `KeepAlive=true`
- `on-failure` → systemd: `Restart=on-failure`, launchd: `KeepAlive={SuccessfulExit=false}`
- `never` → systemd: `Restart=no`, launchd: `KeepAlive=false`

**Environment variables:**
- **systemd**: Uses `Environment=` and `EnvironmentFile=`
- **launchd**: Uses `EnvironmentVariables` dict in plist

### Unique Platform Features

**Systemd-only:**
- Rich dependency system (wants, requires, after, before)
- Advanced security (namespaces, syscall filtering, capabilities)
- Socket activation
- Timer units
- Resource limits via cgroups

**Launchd-only:**
- Event-driven triggers (watchPaths, queueDirectories)
- Calendar-based scheduling (built-in, no separate timer units)
- Process type classification (Background, Interactive, etc.)
- Mach services (XPC)
- Network state awareness

## Future Work

- [x] ~~Launchd support (macOS)~~ **COMPLETE!**
- [ ] Systemd system services (not just user services)
- [ ] Runit support
- [ ] BSD rc.d support (FreeBSD, OpenBSD, NetBSD, DragonFly)
- [ ] Validation and warnings for incompatible options
- [ ] Migration tooling from existing service definitions
- [ ] Integration with home-manager and nix-darwin
- [ ] Socket activation support (both systemd and launchd)
- [ ] Enhanced timer/scheduling support

## Related Documentation

See `../cross-service-plan.md` for the full design document.

## Testing

### Basic Systemd Test

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

### Launchd Test Suite

Run the comprehensive launchd test suite:

```bash
# Build all tests
nix-build services/tests/launchd-test.nix -A all

# View generated plists
ls -l result/

# Inspect a specific test
cat result/basic-test.plist

# Validate plist format (macOS only)
plutil -lint result/basic-test.plist
```

The test suite includes:
- Basic service with minimal options
- Environment variables and PATH configuration
- Calendar-based scheduling (single and multiple intervals)
- Event-driven triggers (watchPaths)
- Resource limits
- KeepAlive conditions
- Working directory and preStart hooks

### Cross-Platform Examples

Test that the same service definition works on both platforms:

```bash
# Build both systemd and launchd versions
nix-build services/examples/sqlite-simple-launchd.nix

# Compare outputs
cat result-systemdService/sqlite-logger.service
cat result-launchdUserAgent/sqlite-logger.plist
```
