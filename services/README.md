# Cross-Service Interface Implementation

This directory contains the implementation of a unified service management interface that works across different service managers (systemd, launchd, runit, BSD rc.d).

## Status

**Phase 9 Complete**: Initramfs/initrd support for advanced boot scenarios!

✅ Core module infrastructure
✅ Common service options (command, args, environment, user, lifecycle hooks, etc.)
✅ Systemd translation layer
✅ Systemd user service generation
✅ Systemd system service generation
✅ Launchd translation layer
✅ Launchd user agent & daemon generation
✅ Runit translation layer
✅ Runit service directory generation
✅ BSD rc.d translation layer
✅ BSD rc.d script generation (FreeBSD/OpenBSD/NetBSD/DragonFly)
✅ Cross-platform examples (systemd + launchd + runit + rc.d)
✅ Configuration validation system
✅ Build-time error detection and warnings
✅ Bootable ekaos system integration
✅ systemd-boot UEFI bootloader support
✅ Complete boot path: UEFI → systemd-boot → kernel → systemd
✅ QEMU/VM testing infrastructure
✅ Automated boot testing
✅ Disk image generation (QCOW2)
✅ **Initramfs/initrd support** (NEW!)
✅ **Two-stage boot (stage-1 + stage-2)** (NEW!)
✅ **LUKS encryption support** (NEW!)
✅ **Linux kernel package integration with core-pkgs** (NEW!)
✅ Full user/system service parity across platforms
✅ Working prototypes with SQLite service and HTTP server
🔄 **System build testing in progress**

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
│   ├── runit-options.nix      # Runit-specific options
│   ├── runit-translate.nix    # Common → runit service directory
│   ├── rcd-options.nix        # BSD rc.d-specific options
│   ├── rcd-translate.nix      # Common → BSD rc.d script
│   ├── validate.nix           # Configuration validation (NEW!)
│   └── service-module.nix     # Core module infrastructure
├── examples/
│   ├── simple-test.nix                  # Minimal test service
│   ├── sqlite-simple.nix                # SQLite logger (systemd user)
│   ├── sqlite-simple-launchd.nix        # SQLite logger (cross-platform)
│   ├── sqlite-server.nix                # SQLite HTTP server (systemd user)
│   ├── http-server-launchd.nix          # HTTP server (cross-platform)
│   ├── http-server-rcd.nix              # HTTP server (BSD rc.d) (NEW!)
│   ├── nginx-system.nix                 # Nginx daemon (system service)
│   └── http-server-cross-platform.nix   # HTTP server (all 7 builders!) (UPDATED!)
├── tests/
│   ├── launchd-test.nix       # Launchd test suite
│   ├── systemd-system-test.nix # Systemd system services tests
│   ├── rcd-test.nix           # BSD rc.d test suite
│   └── validation-test.nix    # Configuration validation tests (NEW!)
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

      # Runit-specific options
      runit = {
        logScript = ''
          #!/bin/sh
          exec svlogd -tt /var/log/my-service
        '';
      };

      # BSD rc.d-specific options
      rcd = {
        variant = "freebsd"; # or "openbsd", "netbsd", "dragonfly"
        rcRequire = [ "DAEMON" "NETWORKING" ];
        rcKeywords = [ "shutdown" ];
        pidfile = "/var/run/my-service.pid";
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
  runitService = services.buildRunitServices serviceConfig;
  rcdService = services.buildRcdServices serviceConfig;            # FreeBSD/NetBSD/DragonFly
  rcdServiceOpenBSD = services.buildRcdServicesOpenBSD serviceConfig; # OpenBSD
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

#### Runit - Service

```bash
# Build the service directory
nix-build -A runitService

# Install to service directory
sudo mkdir -p /etc/sv
sudo cp -r result/my-service /etc/sv/

# Enable and start (creates supervision)
sudo ln -s /etc/sv/my-service /run/service/
# Or on some systems: sudo ln -s /etc/sv/my-service /var/service/

# Check status
sudo sv status my-service

# Control commands
sudo sv up my-service      # Start
sudo sv down my-service    # Stop
sudo sv restart my-service # Restart
sudo sv once my-service    # Run once without supervision

# View logs (if logging configured)
tail -f /var/log/my-service/current

# Disable service
sudo rm /run/service/my-service  # Or /var/service/my-service
```

**Note**: Runit service directories contain a `run` script (required) and optional `finish` script. The service is supervised by `runsv` and restarts automatically on exit unless disabled.

#### BSD rc.d - FreeBSD/NetBSD/DragonFly

```bash
# Build the rc.d service files
nix-build -A rcdService

# Install to service directory
sudo cp result/etc/rc.d/my-service /usr/local/etc/rc.d/
sudo chmod +x /usr/local/etc/rc.d/my-service

# View sample rc.conf configuration
cat result/etc/rc.conf.d/my-service.sample

# Add to /etc/rc.conf to enable
echo 'my_service_enable="YES"' | sudo tee -a /etc/rc.conf

# Start the service
sudo service my-service start

# Check status
sudo service my-service status

# Control commands
sudo service my-service stop      # Stop
sudo service my-service restart   # Restart
sudo service my-service reload    # Reload (sends SIGHUP)

# Service will start automatically at boot
```

**Note**: BSD rc.d services use rcorder (FreeBSD/NetBSD/DragonFly) for dependency-based ordering. The PROVIDE/REQUIRE metadata in the script controls boot sequence. Services do **not** auto-restart on failure.

#### BSD rc.d - OpenBSD

```bash
# Build the OpenBSD rc.d service files
nix-build -A rcdServiceOpenBSD

# Install to service directory
sudo cp result/etc/rc.d/my-service /etc/rc.d/
sudo chmod +x /etc/rc.d/my-service

# Enable using rcctl (recommended)
sudo rcctl enable my-service

# Or manually add to /etc/rc.conf.local
echo 'pkg_scripts="${pkg_scripts} my-service"' | sudo tee -a /etc/rc.conf.local

# Start the service
sudo rcctl start my-service
# Or: sudo /etc/rc.d/my-service start

# Check status
sudo rcctl check my-service

# Control commands
sudo rcctl stop my-service        # Stop
sudo rcctl restart my-service     # Restart
sudo rcctl reload my-service      # Reload (sends SIGHUP)

# View service flags
sudo rcctl get my-service

# Service will start automatically at boot
```

**Note**: OpenBSD rc.d uses sequential ordering (no rcorder). Services are started in alphabetical order. The `rcctl` utility is the recommended way to manage services.

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

## Configuration Validation

The service system includes **automatic build-time validation** to catch configuration errors early:

### Error Detection (Build Fails)

The validation system catches critical errors at build time:

1. **Platform-specific options on wrong builder**
   ```nix
   services.buildLaunchdUserAgents {
     bad-service = {
       enable = true;
       command = "${pkgs.coreutils}/bin/echo";
       systemd = {  # ERROR: Using systemd.* in launchd build
         serviceConfig.PrivateTmp = true;
       };
     };
   }
   # Error: Using systemd.* options in launchd build - these options will be ignored
   ```

2. **Missing required configuration**
   ```nix
   my-service = {
     enable = true;
     command = "";  # ERROR: Empty command
   };
   # Error: command is required but not specified
   ```

3. **Invalid configuration values**
   ```nix
   my-service = {
     enable = true;
     command = "${pkgs.coreutils}/bin/echo";
     restartPolicy = "invalid-policy";  # ERROR: Invalid value
   };
   # Error: Invalid restartPolicy 'invalid-policy' - must be one of: always, on-failure, ...
   ```

### Warning Detection (Build Succeeds)

The validation system issues warnings for non-critical issues:

1. **Limited platform support**
   ```nix
   services.buildLaunchdUserAgents {
     service = {
       enable = true;
       command = "${pkgs.coreutils}/bin/echo";
       postStart = "echo done";  # WARNING: Limited launchd support
     };
   }
   # Warning: postStart hook has limited support on launchd - may need wrapper script
   ```

2. **Platform limitations**
   ```nix
   services.buildRcdServices {
     service = {
       enable = true;
       command = "${pkgs.coreutils}/bin/echo";
       restartPolicy = "always";  # WARNING: Not supported on rc.d
     };
   }
   # Warning: restartPolicy 'always' not supported on BSD rc.d
   ```

3. **Best practice violations**
   ```nix
   my-service = {
     enable = true;
     description = "";  # WARNING: Empty description
     command = "${pkgs.coreutils}/bin/echo";
   };
   # Warning: description is empty - consider adding a human-readable description
   ```

### Validation Categories

The validation system checks for:

- **Platform-specific options on wrong builder** - Detects when you use systemd/launchd/runit/rcd-specific options with the wrong build function
- **Unsupported common options** - Warns when common options have limited support on a platform (e.g., `postStart` on launchd, `restartPolicy` on rc.d)
- **Missing required dependencies** - Ensures `command` and other required fields are set
- **Configuration conflicts** - Catches invalid values for typed options like `restartPolicy`

### Testing Validation

Run the validation test suite to see all validation cases:

```bash
# Run all validation tests
nix-build services/tests/validation-test.nix -A all

# View test results
cat result/test-results.txt

# Test specific error cases
nix-build services/tests/validation-test.nix -A test1_platformSpecificError  # Should fail
nix-build services/tests/validation-test.nix -A test5_emptyCommandError      # Should fail

# Test warning cases
nix-build services/tests/validation-test.nix -A test3_postStartWarning        # Succeeds with warning
nix-build services/tests/validation-test.nix -A test4_restartPolicyWarning    # Succeeds with warning
```

The test suite includes 12 comprehensive tests covering:
- 4 error detection tests (build failures)
- 8 warning detection tests (build succeeds with warnings)

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

## Runit-Specific Options

Under `runit = { ... }`:

### Service Directory
- `superviseDirectory` - Where service will be installed (default: `/etc/sv/<name>`)

### Lifecycle & Logging
- `logScript` - Optional logging run script (typically uses `svlogd`)
- `timeoutFinish` - Max seconds to wait for finish script
- `extraRunScript` - Additional shell code in run script (e.g., `ulimit` settings)
- `extraFinishScript` - Additional shell code in finish script

### Advanced Options
- `extraConfig.checkScript` - Optional health check script content

**Key Behaviors:**
- Services restart automatically on exit (supervised by `runsv`)
- `preStart` hook runs before exec in run script
- `postStop` hook runs in optional finish script
- User/group switching via `chpst -u user:group`
- Environment variables exported in run script
- Working directory changed via `cd` in run script

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

These options work consistently across systemd, launchd, and runit:
- `enable`, `description`, `command`, `args`
- `workingDirectory`, `user`, `group`
- `environment`, `path`
- `restartPolicy` (automatically translated)

### Platform-Specific Behaviors

**preStart hooks:**
- **systemd**: Runs as separate ExecStartPre unit
- **launchd**: Wrapped in shell script before main command
- **runit**: Inline shell code before exec in run script

**postStart/postStop:**
- **systemd**: Full support via ExecStartPost/ExecStopPost
- **launchd**: Limited support (warnings issued, needs wrapper scripts)
- **runit**: postStop via optional finish script (receives exit code and signal)

**Restart policies:**
- `always` → systemd: `Restart=always`, launchd: `KeepAlive=true`, runit: default behavior
- `on-failure` → systemd: `Restart=on-failure`, launchd: `KeepAlive={SuccessfulExit=false}`, runit: default behavior
- `never` → systemd: `Restart=no`, launchd: `KeepAlive=false`, runit: use `sv once` to run without supervision

**Environment variables:**
- **systemd**: Uses `Environment=` and `EnvironmentFile=`
- **launchd**: Uses `EnvironmentVariables` dict in plist
- **runit**: Shell `export` statements in run script

**User/Group switching:**
- **systemd**: `User=` and `Group=` directives
- **launchd**: `UserName=` and `GroupName=` keys
- **runit**: `chpst -u user:group` command wrapper

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

**Runit-only:**
- Extremely simple shell script format (easy to debug)
- Built-in process supervision (runsv monitors and restarts)
- Optional logging via separate log/run script
- Health checks via optional check script
- Minimal dependencies (just shell and basic Unix tools)

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

**Runit:**

Runit doesn't distinguish between user and system services. All services are system-level and controlled via `sv` commands. User-level services would require a separate runit supervision tree running as that user.

| Aspect | Runit Service |
|--------|---------------|
| **Installation** | `/etc/sv/<name>/` (definition), `/run/service/<name>` or `/var/service/<name>` (activation) |
| **Control Command** | `sudo sv` |
| **Format** | Shell script directory (run, optional finish/check/log) |
| **Builder Function** | `buildRunitServices` |
| **Auto-start** | When symlinked to service directory |

## Integration with ekaos Bootable System

The service management infrastructure is now integrated into **ekaos**, a minimal bootable Linux system with systemd. This provides a complete boot-to-service path.

### What is ekaos?

ekaos (`../ekaos/`) is a bootable system builder that:
- Creates complete Linux system closures
- Supports systemd-boot UEFI bootloader
- Uses the services/ infrastructure for system service management
- Provides a NixOS-style module system for configuration
- Generates RFC-0125 compliant bootspec (boot.json)

### Boot Process

**Without initramfs (direct boot):**
```
UEFI Firmware
    ↓
systemd-boot (reads /boot/loader/entries/)
    ↓
Linux Kernel (with init=/nix/store/.../init)
    ↓
Stage-2 Init
    ├─ Mount filesystems (/proc, /sys, /dev, /run)
    ├─ Mount /nix/store (read-only)
    ├─ Run activation scripts
    └─ exec systemd (PID 1)
        ↓
    Systemd Services (managed via services/ interface)
        ↓
    multi-user.target
```

**With initramfs (two-stage boot):**
```
UEFI Firmware
    ↓
systemd-boot (reads /boot/loader/entries/)
    ↓
Linux Kernel (with initrd, init=/init in initramfs)
    ↓
Stage-1 Init (initramfs)
    ├─ Mount essential filesystems (/proc, /sys, /dev, /run)
    ├─ Load kernel modules (SATA, NVMe, USB, etc.)
    ├─ Unlock LUKS encrypted devices
    ├─ Mount root filesystem
    └─ switch_root to real root
        ↓
    Stage-2 Init
        ├─ Mount /nix/store (read-only)
        ├─ Run activation scripts
        └─ exec systemd (PID 1)
            ↓
        Systemd Services (managed via services/ interface)
            ↓
        multi-user.target
```

### Using Services in ekaos

Define system services in ekaos configuration using the same interface:

```nix
# ekaos system configuration
{ config, lib, pkgs, ... }:

{
  system.ekaos.version = "24.11";

  boot.loader.systemd-boot.enable = true;
  boot.kernelPackages = pkgs.linuxPackages;

  # Services use the same interface as services/
  systemd.services = {
    my-service = {
      enable = true;
      description = "My Service";
      command = "${pkgs.python3}/bin/python3";
      args = [ "-m" "http.server" "8080" ];
      restartPolicy = "always";

      environment = {
        PORT = "8080";
      };

      # Systemd-specific options still work
      systemd.serviceConfig = {
        PrivateTmp = true;
      };
    };
  };
}
```

Build a bootable system:

```bash
cd /home/jon/projects/core-pkgs
nix-build ekaos -A system

# Result contains:
./result/init                 # Stage-2 init script
./result/boot.json           # Bootspec for bootloader
./result/etc/                # System configuration
./result/sw/                 # System packages
./result/systemd/            # Systemd package
./result/activate            # Activation script
```

### Benefits of Integration

1. **Unified Service Interface**: Same service definitions work for:
   - Standalone systemd services (user/system)
   - Full bootable ekaos systems
   - All other supported platforms (launchd, runit, rc.d)

2. **Cross-Platform Development**: Develop services on any platform, deploy to ekaos

3. **Validation**: Build-time validation catches errors before boot

4. **Modular**: Services can be defined in modules and reused across systems

### ekaos Features

- **Module System**: NixOS-inspired configuration modules
- **systemd-boot**: Modern UEFI bootloader with automatic generation management
- **Bootspec Compliant**: RFC-0125 boot.json for reliable boot configuration
- **Initramfs/initrd**: Two-stage boot with LUKS encryption, LVM, custom modules
- **Activation Framework**: Topologically sorted system setup scripts
- **/etc Management**: Declarative system configuration files
- **QEMU/VM Testing**: Complete testing infrastructure with automated boot tests
- **Disk Image Builder**: Automated QCOW2 image generation for VMs

### Kernel Package Integration

ekaos uses Linux kernel packages from core-pkgs. The kernel packages are exposed at the top level:

```nix
# Available kernel packages:
pkgs.linuxPackages           # Default stable kernel (linux_6_12)
pkgs.linuxPackages_latest    # Latest kernel (linux_6_18)
pkgs.linuxPackages_6_12      # Specific version 6.12
pkgs.linuxPackages_6_18      # Specific version 6.18
```

**Important**: You must explicitly set `boot.kernelPackages` in your ekaos configuration:

```nix
{ config, pkgs, ... }:
{
  # Required: Select kernel package
  boot.kernelPackages = pkgs.linuxPackages;

  # Or use latest kernel:
  # boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  # ... rest of configuration
}
```

The kernel packages include:
- `kernel` - The Linux kernel itself
- `modules` - Kernel modules for the selected version
- All necessary tools for building initramfs and kernel modules

### Example: Bootable HTTP Server

Create a complete bootable system with an HTTP server:

```nix
{ config, pkgs, ... }:

{
  system.ekaos.label = "http-server-system";

  boot.loader.systemd-boot.enable = true;
  boot.kernelPackages = pkgs.linuxPackages;

  systemd.services.http-server = {
    enable = true;
    description = "HTTP Server";
    command = "${pkgs.python3}/bin/python3";
    args = [ "-m" "http.server" "8080" ];
    restartPolicy = "always";

    systemd = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
    };
  };
}
```

Build and test in a VM:

```bash
# Add VM support to configuration
{ config, pkgs, ... }:
{
  # ... HTTP server configuration above ...

  # Enable VM testing
  virtualisation.enable = true;
}

# Build and run
nix-build -A vm
./result  # Boots VM with HTTP server running
```

Or install to disk and boot on real hardware!

### Current Status

- ✅ **Core boot infrastructure** - Stage-2 init, activation, /etc management
- ✅ **systemd-boot integration** - UEFI bootloader with boot entry generation
- ✅ **Service integration** - services/ infrastructure used for system services
- ✅ **Bootspec generation** - RFC-0125 compliant boot.json
- ✅ **QEMU/VM testing** - Complete testing infrastructure with automated tests
- ✅ **Disk image creation** - Automated QCOW2 image generation for VMs
- ✅ **Boot verification** - One-command testing with `./tests/quick-test.sh`
- ✅ **Initramfs/initrd support** - Two-stage boot for encrypted root, LVM, custom modules
- ✅ **Kernel package integration** - Linux kernel packages exposed at top-level in core-pkgs
- 🔄 **System build testing** - Currently verifying complete build process

### Recent Changes (Phase 9)

**Initramfs/Initrd Implementation:**
- Complete two-stage boot support with stage-1 init in initramfs
- LUKS encryption support with cryptsetup integration
- Kernel module loading for SATA, NVMe, USB, VirtIO devices
- Filesystem support for ext4, btrfs, xfs, vfat
- Busybox-based minimal environment for stage-1

**Kernel Package Integration:**
- Added `linuxPackages`, `linuxPackages_latest`, `linuxPackages_6_12`, `linuxPackages_6_18` to `top-level.nix`
- Kernel packages built using `packagesFor` function from linux scope
- Users must explicitly set `boot.kernelPackages` in configuration
- All required kernel modules and tools available for initramfs building

**Module System Improvements:**
- Fixed circular dependency issues in kernel module
- Proper integration with core-pkgs package set
- Services library path corrections for ekaos integration
- Bootspec JSON structure fixed for proper attribute merging

### Quick Test

Test ekaos boot in QEMU:

```bash
cd /home/jon/projects/core-pkgs/ekaos
./tests/quick-test.sh
```

This builds a bootable VM, boots it, and verifies successful systemd startup in ~30 seconds.

See `../ekaos/README.md` for complete ekaos documentation and testing options.

## Future Work

- [x] ~~Launchd support (macOS)~~ **COMPLETE!**
- [x] ~~Systemd system services~~ **COMPLETE!**
- [x] ~~Runit support~~ **COMPLETE!**
- [x] ~~BSD rc.d support (FreeBSD, OpenBSD, NetBSD, DragonFly)~~ **COMPLETE!**
- [x] ~~Validation and warnings for incompatible options~~ **COMPLETE!**
- [x] ~~Bootable system integration (ekaos with systemd-boot)~~ **COMPLETE!**
- [x] ~~Boot testing in QEMU/VM~~ **COMPLETE!**
- [x] ~~Initrd/initramfs support for ekaos~~ **COMPLETE!**
- [ ] Real hardware boot testing
- [ ] Migration tooling from existing service definitions
- [ ] Integration with home-manager and nix-darwin
- [ ] Socket activation support (systemd, launchd, runit, and BSD rc.d)
- [ ] Enhanced timer/scheduling support
- [ ] GRUB bootloader support for ekaos
- [ ] Network configuration modules for ekaos
- [ ] User management modules for ekaos
- [ ] Network root filesystem (iSCSI/NFS) in initramfs

## Related Documentation

- `../cross-service-plan.md` - Full design document for cross-service interface
- `../ekaos/README.md` - ekaos bootable system documentation
- `../ekaos/missing-packages.md` - Package requirements for bootable systems

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
