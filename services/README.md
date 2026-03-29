# Cross-Service Interface Implementation

This directory contains the implementation of a unified service management interface that works across different service managers (systemd, launchd, runit, BSD rc.d).

## Status

**Phase 3 Complete**: Systemd system services added!

✅ Core module infrastructure
✅ Common service options (command, args, environment, user, lifecycle hooks, etc.)
✅ Systemd translation layer
✅ Systemd user service generation
✅ **Systemd system service generation** (NEW!)
✅ **Launchd translation layer**
✅ **Launchd user agent & daemon generation**
✅ **Cross-platform examples (systemd + launchd)**
✅ **Full user/system service parity across platforms**
✅ Working prototypes with SQLite service and HTTP server

## Architecture

```
services/
├── lib/
│   ├── types.nix              # Custom types for service definitions
│   ├── options.nix            # Common service options
│   ├── systemd-options.nix    # Systemd-specific options (user & system)
│   ├── systemd-translate.nix  # Common → systemd translation
│   ├── launchd-options.nix    # Launchd-specific options
│   ├── launchd-translate.nix  # Common → launchd plist translation
│   └── service-module.nix     # Core module infrastructure
├── examples/
│   ├── simple-test.nix                  # Minimal test service
│   ├── sqlite-simple.nix                # SQLite logger (systemd user)
│   ├── sqlite-simple-launchd.nix        # SQLite logger (cross-platform)
│   ├── sqlite-server.nix                # SQLite HTTP server (systemd user)
│   ├── http-server-launchd.nix          # HTTP server (cross-platform)
│   ├── nginx-system.nix                 # Nginx daemon (system service) (NEW!)
│   └── http-server-cross-platform.nix   # HTTP server (all 4 builders) (NEW!)
├── tests/
│   ├── launchd-test.nix       # Launchd test suite
│   └── systemd-system-test.nix # Systemd system services tests (NEW!)
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
  # Build for different platforms and contexts
  systemdUserService = services.buildSystemdUserServices serviceConfig;
  systemdSystemService = services.buildSystemdSystemServices serviceConfig;
  launchdUserAgent = services.buildLaunchdUserAgents serviceConfig;
  launchdDaemon = services.buildLaunchdDaemons serviceConfig;
}
```

### Building and Installing

#### Linux (systemd) - User Service

```bash
# Build the user service file
nix-build -A systemdUserService

# Install to user systemd directory
cp result/my-service.service ~/.config/systemd/user/

# Reload and start
systemctl --user daemon-reload
systemctl --user start my-service
systemctl --user status my-service
```

#### Linux (systemd) - System Service

```bash
# Build the system service file
nix-build -A systemdSystemService

# Install to system directory (requires sudo)
sudo cp result/my-service.service /etc/systemd/system/

# Reload and start
sudo systemctl daemon-reload
sudo systemctl start my-service
sudo systemctl status my-service

# Enable at boot (optional)
sudo systemctl enable my-service

# View logs
sudo journalctl -u my-service -f
```

**Note**: System services automatically use `multi-user.target` instead of `default.target`. If you don't specify `wantedBy`, it will default to the appropriate target based on whether you use `buildSystemdUserServices` or `buildSystemdSystemServices`.

#### macOS (launchd) - User Agent

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

#### macOS (launchd) - System Daemon

```bash
# Build the daemon plist
nix-build -A launchdDaemon

# Install to system LaunchDaemons directory (requires sudo)
sudo cp result/my-service.plist /Library/LaunchDaemons/

# Load and start
sudo launchctl load /Library/LaunchDaemons/my-service.plist

# Check status
sudo launchctl list | grep my-service

# Unload (to stop)
sudo launchctl unload /Library/LaunchDaemons/my-service.plist
```

**Note**: Launchd uses the same plist format for both user agents and system daemons. The installation location determines the context (user vs system).

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

## User vs System Services Comparison

| Aspect | User Service | System Service |
|--------|--------------|----------------|
| **Installation** | `~/.config/systemd/user/` | `/etc/systemd/system/` |
| **Control Command** | `systemctl --user` | `systemctl` (requires sudo) |
| **Default WantedBy** | `default.target` | `multi-user.target` |
| **Permissions** | Runs as user | Runs as specified user (or root) |
| **Builder Function** | `buildSystemdUserServices` | `buildSystemdSystemServices` |
| **Auto-start** | At user login | At system boot |
| **Dependencies** | Other user services | System targets (network.target, etc.) |

**Launchd Comparison:**

| Aspect | User Agent | System Daemon |
|--------|------------|---------------|
| **Installation** | `~/Library/LaunchAgents/` | `/Library/LaunchDaemons/` |
| **Control Command** | `launchctl` | `sudo launchctl` |
| **Plist Format** | Identical | Identical |
| **Builder Function** | `buildLaunchdUserAgents` | `buildLaunchdDaemons` |
| **Auto-start** | At user login | At system boot |

## Future Work

- [x] ~~Launchd support (macOS)~~ **COMPLETE!**
- [x] ~~Systemd system services~~ **COMPLETE!**
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

### Systemd System Services Test Suite

Run the comprehensive systemd system services test suite:

```bash
# Build all tests
nix-build services/tests/systemd-system-test.nix -A all

# View test results and verification
cat result/test-results.txt

# Inspect individual service files
ls -l result/*.service

# Compare user vs system service for same config
diff result/compare-user.service result/compare-system.service
```

The test suite verifies:
- Basic system service generation
- Automatic `multi-user.target` default (vs `default.target` for user services)
- Custom `wantedBy` override
- Non-root user service with User/Group directives
- PreStart and postStop hooks
- Environment variables and PATH
- Restart policies (always, on-failure)
- Network dependencies (wants, requires, after)

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

Test that the same service definition works across all builders:

```bash
# Build all four variants (user + system, systemd + launchd)
nix-build services/examples/http-server-cross-platform.nix

# Compare outputs
cat result-systemdUserService/http-server.service
cat result-systemdSystemService/http-server.service
cat result-launchdUserAgent/http-server.plist
cat result-launchdDaemon/http-server.plist

# See the automatic wantedBy adjustment
diff result-systemdUserService/http-server.service \
     result-systemdSystemService/http-server.service
```

### Example: Nginx System Daemon

Build and inspect a real-world system service example:

```bash
# Build nginx as a system service
nix-build services/examples/nginx-system.nix -A systemdSystemService

# View the generated service file
cat result/nginx.service

# Compare with user service variant
nix-build services/examples/nginx-system.nix -A systemdUserService
diff result-systemdUserService/nginx.service \
     result-systemdSystemService/nginx.service
```
