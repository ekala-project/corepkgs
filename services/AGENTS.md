# Agent Guide for Cross-Service Interface

This document provides a quick reference for AI agents working with the cross-platform service management system in core-pkgs.

## Overview

The `services/` directory provides a **unified service interface** that works across multiple service managers:
- **systemd** (Linux - user & system services)
- **launchd** (macOS - user agents & system daemons)
- **runit** (Linux/containers - simple supervision)
- **BSD rc.d** (FreeBSD/OpenBSD/NetBSD/DragonFly)

Services are defined once using common options, then automatically translated to platform-specific formats.

## Service Definition Structure

```nix
{
  services.my-service = {
    # Common options (work everywhere)
    enable = true;
    description = "My Service";
    command = "${pkgs.python3}/bin/python3";
    args = [ "-m" "http.server" "8080" ];
    user = "myuser";
    workingDirectory = "/var/lib/myservice";
    environment = { PORT = "8080"; };
    restartPolicy = "always";  # or "on-failure", "never"
    preStart = "echo 'Starting...'";
    postStop = "echo 'Stopped'";

    # Platform-specific extensions (optional)
    systemd = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };

    launchd = {
      label = "com.example.my-service";
      keepAlive = true;
      runAtLoad = true;
    };

    runit = {
      logScript = ''
        #!/bin/sh
        exec svlogd -tt /var/log/my-service
      '';
    };

    rcd = {
      variant = "freebsd";  # or "openbsd", "netbsd", "dragonfly"
      rcRequire = [ "NETWORKING" ];
    };
  };
}
```

## Integration with ekaos

ekaos modules use the same service interface. Services are defined at `services.*` and automatically translated to systemd units.

**Example ekaos module:**
```nix
{ config, pkgs, ... }:

{
  services.my-app = {
    enable = true;
    command = "${pkgs.myapp}/bin/myapp";
    restartPolicy = "always";

    systemd = {
      wantedBy = [ "multi-user.target" ];
    };
  };
}
```

**Location:** Service modules are in `ekaos/modules/services/`

## ekaos Service Module Conventions

When creating ekaos service modules:

1. **Standard service options** - Always include:
   - `enable` (bool)
   - `description` (str, default provided)
   - `command` (str, internal/automatic)
   - `args` (list of str, internal/automatic)
   - `user` (str, defaults to appropriate user)
   - `restartPolicy` (str, usually "always")
   - `systemd` (attrset for systemd-specific options)

2. **Application-specific settings** - Use `settings` submodule:
   ```nix
   services.openssh.settings = {
     ports = 22;
     permitRootLogin = "prohibit-password";
     passwordAuthentication = true;
   };
   ```

3. **Service definition** - Set in config section:
   ```nix
   config = mkIf cfg.enable {
     services.openssh = {
       command = "${pkgs.openssh}/bin/sshd";
       args = [ "-D" "-f" "${sshdConfig}" ];
       user = "root";
       restartPolicy = "always";

       systemd = {
         after = [ "network.target" ];
         wantedBy = [ "multi-user.target" ];
       };
     };
   };
   ```

## Porting Services from nixpkgs

When porting service modules from nixpkgs to ekaos, refactor them to use the reusable services interface.

### Refactoring Pattern

**ekaos reusable style:**
```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.services.myservice;
in

{
  options.services.myservice = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable My Service.";
    };

    description = mkOption {
      type = types.str;
      default = "My Service";
      description = "Service description";
    };

    command = mkOption {
      type = types.str;
      internal = true;
      description = "Command to run (set automatically)";
    };

    args = mkOption {
      type = types.listOf types.str;
      internal = true;
      default = [];
      description = "Command arguments (set automatically)";
    };

    user = mkOption {
      type = types.str;
      default = "myservice";
      description = "User to run service as";
    };

    restartPolicy = mkOption {
      type = types.str;
      default = "always";
      description = "Restart policy";
    };

    systemd = mkOption {
      type = types.attrsOf types.anything;
      default = {};
      description = "Systemd-specific options";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 8080;
            description = "Port to listen on";
          };
          # Other application-specific options
        };
      };
      default = {};
      description = "Application-specific configuration";
    };
  };

  config = mkIf cfg.enable {
    # Define using cross-platform interface
    services.myservice = {
      command = "${pkgs.myservice}/bin/myservice";
      args = [ "--port" (toString cfg.settings.port) ];
      user = cfg.user;
      restartPolicy = "always";

      systemd = {
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
      };
    };
  };
}
```

### Key Changes

1. **Add standard service options**:
   - `description` (str, with default)
   - `command` (str, internal)
   - `args` (list of str, internal)
   - `user` (str, with default)
   - `restartPolicy` (str, usually "always")
   - `systemd` (attrset for systemd-specific options)

3. **Nest application-specific options** under `settings`:
   ```nix
   # Before:
   services.myservice.port = 8080;

   # After:
   services.myservice.settings.port = 8080;
   ```

4. **Set command/args in config** section (not options):
   ```nix
   config = mkIf cfg.enable {
     services.myservice = {
       command = "${pkgs.myservice}/bin/myservice";
       args = [ "--port" (toString cfg.settings.port) ];
       # ... other options
     };
   };
   ```

5. **Systemd-specific options** in `systemd = {}` block:
   ```nix
   services.myservice.systemd = {
     wantedBy = [ "multi-user.target" ];
     after = [ "network.target" ];
     serviceConfig = {
       PrivateTmp = true;
     };
   };
   ```

### Complete Example: OpenSSH

See `ekaos/modules/services/networking/sshd.nix` for a complete working example showing:
- Standard service options (enable, description, command, args, user, restartPolicy, systemd)
- Application-specific `settings` submodule (ports, permitRootLogin, passwordAuthentication, etc.)
- Config generation (sshd_config file)
- Service definition using cross-platform interface
- Activation scripts for host key generation

### Validation Checklist

After porting, ensure:
- [ ] Standard service options defined (enable, description, command, args, user, restartPolicy, systemd)
- [ ] Application-specific options nested under `settings` submodule
- [ ] `command` and `args` set in config section (internal options)
- [ ] Systemd-specific options moved to `systemd = {}` block
- [ ] Service definition uses `services.*`
- [ ] All option references updated (e.g., `cfg.port` → `cfg.settings.port`)
- [ ] Test that service evaluates: `nix-instantiate -A ekaosTests.myservice`

## Common Options Reference

All platforms support:
- `enable` - Enable the service
- `description` - Human-readable description
- `command` - Main executable path
- `args` - Command arguments (list)
- `workingDirectory` - Working directory
- `user` / `group` - User/group context
- `environment` - Environment variables (attrset)
- `path` - Packages to add to PATH (list)
- `restartPolicy` - Restart behavior
- `preStart` / `postStart` / `postStop` - Lifecycle hooks

## Platform-Specific Options

Under `systemd = { ... }`:
- `serviceConfig` - [Service] section options
- `unitConfig` - [Unit] section options
- `wants` / `requires` / `after` / `before` - Dependencies
- `wantedBy` - Installation targets

Under `launchd = { ... }`:
- `label` - Service identifier
- `keepAlive` - Restart behavior
- `runAtLoad` - Start at boot/login
- `watchPaths` / `queueDirectories` - Event triggers
- `startCalendarInterval` - Scheduled execution

Under `runit = { ... }`:
- `logScript` - Logging configuration
- `extraRunScript` - Additional run script code
- `extraFinishScript` - Finish script code
- `timeoutFinish` - Finish script timeout

Under `rcd = { ... }`:
- `variant` - BSD variant (freebsd/openbsd/netbsd/dragonfly)
- `rcRequire` - Dependencies
- `rcKeywords` - Service keywords
- `pidfile` - PID file location

## Build Functions

Standalone service files can be built using:
- `services.buildSystemdUserServices serviceConfig`
- `services.buildSystemdSystemServices serviceConfig`
- `services.buildLaunchdUserAgents serviceConfig`
- `services.buildLaunchdDaemons serviceConfig`
- `services.buildRunitServices serviceConfig`
- `services.buildRcdServices serviceConfig`

## Validation

Services are validated at build time:
- **Errors** - Missing required options, invalid values, platform mismatches
- **Warnings** - Limited platform support, best practice violations

## Testing

**Runit test framework** - Module-based testing in sandbox:
```nix
{ pkgs, ... }:
{
  name = "my-test";
  modules = [
    { services.webserver = { enable = true; command = "..."; }; }
  ];
  testScript = ''
    machine.wait_for_open_port(8080)
    machine.succeed("curl http://127.0.0.1:8080")
  '';
}
```

**ekaos test framework** - VM-based system testing:
```nix
{ pkgs, ... }:
{
  name = "service-test";
  testScript = ''
    machine.wait_for_unit("my-service.service")
    machine.succeed("systemctl status my-service")
  '';
}
```

## Directory Structure

```
services/
├── lib/
│   ├── options.nix           # Common service options
│   ├── systemd-translate.nix # systemd translation
│   ├── launchd-translate.nix # launchd translation
│   ├── runit-translate.nix   # runit translation
│   ├── rcd-translate.nix     # rc.d translation
│   ├── validate.nix          # Build-time validation
│   └── service-module.nix    # Core infrastructure
├── examples/                 # Usage examples
├── tests/                    # Test suites
└── README.md                 # Full documentation

ekaos/modules/
├── services.nix              # Service namespace definition
├── systemd.nix               # Systemd integration (consumes services.*)
└── services/                 # Service modules (openssh, dhcpcd, etc.)
```

## Key Concepts

1. **Cross-platform architecture**:
   - `services.*` - Cross-platform definitions (translated by service manager)

2. **Automatic translation**:
   - Common options automatically map to platform-specific formats
   - Platform-specific options available for advanced features

3. **Validation**:
   - Build fails on critical errors
   - Warnings for limited platform support

4. **Module system**:
   - ekaos uses NixOS-style modules
   - Services defined once, used everywhere

## Further Reading

- Full documentation: `services/README.md`
- ekaos documentation: `ekaos/README.md`
- Design document: `cross-service-plan.md`
- Examples: `services/examples/`
- Tests: `services/tests/`
