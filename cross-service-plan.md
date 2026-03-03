# Cross-Service Interface Design

## Executive Summary

### Problem Statement

Modern service management is fragmented across different init systems and service managers:
- **Linux**: systemd (most distributions), runit (Void Linux, some embedded)
- **macOS**: launchd via launchctl
- **BSD**: rc.d (FreeBSD, NetBSD, DragonFly BSD, OpenBSD)

Each system has its own configuration format, capabilities, and paradigms. This makes it difficult to:
1. Write portable service definitions
2. Maintain consistent behavior across platforms
3. Share service definitions between system-wide daemons and user-level services
4. Support both production deployments and development environments

NixOS provides excellent systemd integration via `systemd.services.*`, but lacks a unified abstraction that could work across service managers while preserving platform-specific capabilities.

### Solution Approach

We propose a **two-tier interface design**:

1. **Common Core Layer**: Minimal, guaranteed features that work across all service managers
   - Command execution (program + arguments)
   - User/group context
   - Environment variables
   - Basic restart policies
   - Lifecycle hooks (pre/post start/stop)
   - I/O redirection
   - State directory management

2. **Manager-Specific Extensions**: Opt-in advanced features via namespaced options
   - `systemd.*` - Rich dependencies, security sandboxing, socket activation, timers
   - `launchd.*` - Event-driven triggers, calendar scheduling, Mach services
   - `runit.*` - Logging scripts, finish handlers, check scripts
   - `rcd.*` - BSD rc.d dependencies (PROVIDE/REQUIRE), profiles, jails, pre/post hooks

This approach mirrors NixOS's philosophy of declarative configuration while respecting each service manager's unique strengths and constraints.

### Design Goals

- **Portability**: Common services work everywhere with minimal changes
- **Power**: Platform-specific features remain accessible
- **Safety**: Clear validation and warnings for incompatible options
- **Familiarity**: Similar API to existing `systemd.services.*`
- **Composability**: Enable cross-cutting concerns (like systemd-confinement.nix)
- **Developer Experience**: Same interface for system daemons, user services, dev environments

---

## Service Manager Comparison

### Systemd

**Philosophy**: Comprehensive, feature-rich, declarative init system with extensive security and isolation

**Architecture**:
- Unit-based design (service, socket, timer, target, mount, path, etc.)
- Rich dependency resolution with ordering constraints
- Integrated with kernel features (cgroups, namespaces, capabilities)
- Socket and D-Bus activation for on-demand starting
- Parallel startup based on dependency graph

**Key Strengths**:
- Very rich dependency system: wants, requires, bindsTo, partOf, conflicts, upholds
- Explicit ordering: after, before
- Advanced security/sandboxing:
  - Filesystem isolation (PrivateTmp, ProtectHome, ProtectSystem, ReadOnlyPaths)
  - Namespace isolation (PrivateNetwork, PrivateUsers, PrivateMounts)
  - System call filtering (SystemCallFilter with @groups)
  - Capability management (CapabilityBoundingSet, AmbientCapabilities)
  - Automated user creation (DynamicUser)
- Automatic directory creation with proper ownership (StateDirectory, RuntimeDirectory, etc.)
- Resource management via cgroups (CPU, memory, I/O limits)
- Built-in timer units for scheduling (OnCalendar, OnActiveSec)
- Environment file support for secrets (EnvironmentFile)
- Comprehensive lifecycle hooks (ExecStartPre, ExecStartPost, ExecReload, ExecStop, ExecStopPost)
- Multiple service types (simple, exec, forking, oneshot, notify, dbus, idle)

**Configuration Format**: INI-style unit files

**User Services**: Separate `systemd.user.services` namespace with per-user instances

---

### Launchd (macOS)

**Philosophy**: Event-driven service management integrated with macOS system services

**Architecture**:
- Property list (plist) based configuration
- Event-driven: launch on filesystem changes, network state, calendar intervals, socket connections
- Integrated with macOS security model (sandbox profiles, entitlements)
- Launch-on-demand via socket and Mach service registration
- Per-user agents and system-wide daemons

**Key Strengths**:
- Event-driven launch triggers:
  - Filesystem watching (WatchPaths)
  - Network state changes
  - Calendar intervals (StartCalendarInterval)
  - Periodic intervals (StartInterval)
  - Socket-based on-demand launching
- Mach service integration (machServices key)
- Built-in scheduling without separate timer units
- KeepAlive with conditional restart policies:
  - SuccessfulExit (restart on failure only)
  - NetworkState (start when network available)
  - PathState (start when paths exist)
  - OtherJobEnabled (coordinate with other jobs)
- Process type classification (Standard, Background, Interactive, Adaptive)
- Resource limits via SoftResourceLimits/HardResourceLimits
- Queue directories for batch processing
- macOS-specific features (EnableTransactions, LegacyTimers, etc.)

**Differences from Systemd**:
- No explicit dependency system (relies on event triggers and launch-on-demand)
- No ordering constraints (after/before)
- Less granular security (no namespaces, syscall filtering - uses macOS sandbox)
- No automatic directory creation
- No built-in reload mechanism
- No pre/post lifecycle hooks

**Configuration Format**: XML or binary property lists

**User Services**: Separate user agents (~/Library/LaunchAgents) vs system daemons (/Library/LaunchDaemons)

---

### Runit

**Philosophy**: Minimal, simple, Unix-style process supervision

**Architecture**:
- Service directory based (`/etc/sv/`, `/var/service/`)
- Each service is a directory with executable scripts
- `run` script must keep process in foreground
- Supervision via `runsv` (one per service)
- Service management via `sv` command
- Ultra-lightweight and portable

**Key Strengths**:
- Extreme simplicity: just shell scripts
- Fast and lightweight (minimal overhead)
- Clean process environment guarantee
- Per-service logging via `log/run` subdirectory with svlogd
- Portable across Unix systems
- Service state inspection via `svstat`
- Automatic restart on process exit (unless run script exits successfully)
- Manual dependency handling via symlinks or sv down/up ordering

**Limitations**:
- No built-in dependency system (external orchestration needed)
- No timers (use cron or timer service)
- No socket activation (use external tools)
- No automatic directory creation (handle in run script)
- No built-in security features (use chpst for user/group/limits/chroot)
- Process must not fork (no daemon mode)
- No built-in environment inheritance (use env/ directory or chpst -e)

**Configuration Format**: Executable shell scripts (run, finish, check)

**User Services**: User-level runit via runsvdir in user session

---

### BSD rc.d (FreeBSD, NetBSD, DragonFly BSD, OpenBSD)

**Philosophy**: Shell script-based service management with dependency-ordered initialization

**Architecture**:
- Script-based configuration in `/etc/rc.d/` and `/usr/local/etc/rc.d/`
- Dependency declarations via special comments (PROVIDE, REQUIRE, BEFORE)
- Dynamic ordering via `rcorder(8)` parsing dependency graph
- Configuration in `/etc/rc.conf` (shell variable assignments)
- Extensive library of helper functions in `/etc/rc.subr`
- Each script responds to standard commands (start, stop, restart, status, reload, etc.)
- Reverse dependency order for shutdown

**Key Strengths**:
- Explicit dependency system via rcorder (PROVIDE, REQUIRE, BEFORE)
- Shell script flexibility for complex startup logic
- Rich variable system via rc.subr framework
- Login class integration for resource limits (FreeBSD, NetBSD)
- Service jail support for containerization (FreeBSD)
- Profile support for multiple service instances (FreeBSD)
- Pre/post hooks for all lifecycle operations (start_precmd, stop_postcmd, etc.)
- Easy to debug (standard shell scripting)
- Portable across BSD variants with minor adaptations
- Fine-grained control via rc.conf variables
- Configuration validation hooks (configtest pattern)

**Limitations**:
- No automatic restart/supervision (manual intervention only)
- No built-in timers (use cron or at)
- No socket activation without external tools
- No automatic directory creation (manual in precmd hooks)
- No advanced security features like namespaces (use jails on FreeBSD)
- Resource control limited to rlimit (via login.conf)
- No built-in logging framework (manual redirection or syslog)
- User services not directly supported (system-level only)

**Configuration Format**: Shell scripts with rc.subr framework + rc.conf variables

**User Services**: Not directly supported (system-level services only)

**BSD Variant Differences**:

**FreeBSD**:
- Feature-rich rc.subr with extensive variable set (~50+ options)
- Service jail support (`${name}_svcj`, `${name}_svcj_options`)
- Login class resource limits (`${name}_login_class`, `${name}_limits`)
- Profile support for multiple instances (`${name}_profiles`)
- Human-readable descriptions (`desc` variable)
- Uses `/bin/sh` for script execution
- Package scripts in `/usr/local/etc/rc.d/`

**NetBSD**:
- Original rc.d implementation (FreeBSD imported from NetBSD)
- Very similar to FreeBSD in structure
- Variable interpolation: `rcvar=$name` instead of explicit strings
- Package scripts in `/usr/pkg/share/examples/rc.d` (manual deployment)
- PKG_RCD_SCRIPTS environment variable for automatic script deployment
- Uses `/bin/sh` for script execution
- Full rcorder(8) dependency support

**OpenBSD**:
- **Dramatically simpler** than FreeBSD/NetBSD - deliberately minimalist
- No PROVIDE/REQUIRE/BEFORE dependency comments
- Managed via `rcctl(8)` command instead of direct script invocation
- Much smaller variable set (daemon, daemon_flags, daemon_user, pexp, timeout)
- Uses `pexp` (regex pattern) for process matching with pgrep/pkill
- Uses `/bin/ksh` instead of `/bin/sh`
- Configuration in `/etc/rc.conf.local`
- Framework functions: rc_check, rc_start, rc_stop, rc_reload, rc_pre, rc_post
- Default timeout: 30 seconds for start/stop/reload

**DragonFly BSD**:
- Uses NetBSD's rc.d system
- Forked from FreeBSD 4.8 but adopted NetBSD's rc.d
- Full rcorder(8) dependency parsing
- Similar to NetBSD in operation
- Uses `/bin/sh` for script execution

---

### Feature Comparison Matrix

| Feature | systemd | launchd | runit | BSD rc.d |
|---------|---------|---------|-------|----------|
| **Dependencies** | Rich (wants, requires, bindsTo) | Implicit (events, sockets) | Manual (symlinks, ordering) | Explicit (PROVIDE, REQUIRE, BEFORE) |
| **Ordering** | Explicit (after, before) | No | Manual | rcorder dependency graph |
| **Socket Activation** | Yes (separate socket units) | Yes (Sockets key) | No | External tools only |
| **Timers/Scheduling** | Yes (timer units) | Yes (built-in) | External (cron) | External (cron/at) |
| **Lifecycle Hooks** | Extensive (ExecStart*, ExecStop*) | None (RunAtLoad) | finish script only | Pre/post for all commands |
| **Restart Policies** | Per exit code/signal | KeepAlive + conditions | Always (unless run exits 0) | Manual (no supervision) |
| **Security/Sandboxing** | Very extensive (namespaces, syscalls) | macOS sandbox | Minimal (chpst) | Jails (FreeBSD only) |
| **Resource Limits** | cgroups + rlimit | rlimit | chpst (rlimit) | login.conf (rlimit) |
| **User Context** | User, Group, DynamicUser | UserName, GroupName | chpst -u | ${name}_user in rc.conf |
| **Environment** | Environment, EnvironmentFile | EnvironmentVariables | env/ dir, chpst -e | Export in precmd |
| **State Directories** | Automatic creation | Manual | Manual | Manual (in precmd) |
| **Logging** | journald integration | StandardOutPath/ErrorPath | log/run with svlogd | Syslog or manual redirect |
| **User Services** | systemd --user | LaunchAgents | runsvdir in session | No (system only) |
| **Config Format** | INI-style | XML/binary plist | Shell scripts | Shell scripts + rc.conf |
| **Complexity** | High (200+ options) | Medium (~50 keys) | Very low (just scripts) | Medium (~30-50 vars) |

---

## Proposed Interface Design

### Core Module Structure

```nix
{
  services.<name> = {
    # Core options (common across all service managers)
    enable = ...;
    description = ...;
    command = ...;
    # ... etc

    # Manager-specific extensions
    systemd = { ... };
    launchd = { ... };
    runit = { ... };
  };
}
```

### Common Core Options

These options work across all service managers with automatic translation:

```nix
services.<name> = {
  # Enable/disable service
  enable = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Whether to enable the service. When false, the service
      will not be created or started.
    '';
  };

  # Human-readable description
  description = mkOption {
    type = types.str;
    example = "Example web server";
    description = ''
      A short, human-readable description of the service.
      Used in service manager UIs and status output.
    '';
  };

  # Main command execution
  command = mkOption {
    type = types.either types.path types.str;
    example = literalExpression ''"''${pkgs.nginx}/bin/nginx"'';
    description = ''
      The main command to execute for this service.
      Should be an absolute path to an executable.
    '';
  };

  args = mkOption {
    type = types.listOf types.str;
    default = [];
    example = [ "-c" "/etc/nginx/nginx.conf" "-g" "daemon off;" ];
    description = ''
      Arguments to pass to the command.

      Note: For runit, these will be combined with command into
      the run script. For systemd/launchd, they're kept separate.
    '';
  };

  # Working directory
  workingDirectory = mkOption {
    type = types.nullOr types.path;
    default = null;
    example = "/var/lib/myservice";
    description = ''
      Working directory for the service process.
      If null, uses the service manager's default.
    '';
  };

  # User and group context
  user = mkOption {
    type = types.str;
    default = "root";
    example = "nginx";
    description = ''
      User account under which the service runs.

      systemd: Can use DynamicUser for auto-created users
      launchd: Must be existing user
      runit: Uses chpst -u to change user
    '';
  };

  group = mkOption {
    type = types.str;
    default = "root";
    example = "nginx";
    description = ''
      Primary group for the service process.
    '';
  };

  supplementaryGroups = mkOption {
    type = types.listOf types.str;
    default = [];
    example = [ "audio" "video" ];
    description = ''
      Additional groups for the service process.

      Note: runit support limited (requires explicit chpst args)
    '';
  };

  # Environment variables
  environment = mkOption {
    type = types.attrsOf (types.oneOf [ types.str types.path types.package ]);
    default = {};
    example = literalExpression ''
      {
        LANG = "en_US.UTF-8";
        CONFIG_DIR = "/etc/myservice";
        PKGS = pkgs.myPackage;
      }
    '';
    description = ''
      Environment variables for the service.

      Paths and packages are converted to strings automatically.
      Systemd: Uses Environment= directive
      Launchd: Uses EnvironmentVariables dict
      Runit: Creates env/ directory with files
    '';
  };

  path = mkOption {
    type = types.listOf types.package;
    default = [];
    example = literalExpression ''[ pkgs.coreutils pkgs.gnugrep ]'';
    description = ''
      Packages to add to the service's PATH.
      Both bin/ and sbin/ subdirectories are included.

      Systemd: Uses path= option
      Launchd: Adds to PATH in EnvironmentVariables
      Runit: Generates PATH in run script
    '';
  };

  # Lifecycle hooks
  preStart = mkOption {
    type = types.lines;
    default = "";
    example = ''
      mkdir -p /var/lib/myservice
      chown myuser:mygroup /var/lib/myservice
    '';
    description = ''
      Shell commands to run before starting the main process.

      Systemd: ExecStartPre (separate unit)
      Launchd: Not supported (run in main ProgramArguments wrapper)
      Runit: Inline in run script before exec

      Runs as root unless service manager supports per-hook users.
    '';
  };

  postStart = mkOption {
    type = types.lines;
    default = "";
    example = ''
      echo "Service started at $(date)" >> /var/log/myservice/startup.log
    '';
    description = ''
      Shell commands to run after the main process starts.

      Systemd: ExecStartPost
      Launchd: Not supported
      Runit: Not supported (use check script instead)

      Warning: On launchd/runit, these commands won't run.
    '';
  };

  preStop = mkOption {
    type = types.lines;
    default = "";
    example = ''
      # Notify monitoring system
      curl -X POST https://monitor.example.com/stopping
    '';
    description = ''
      Shell commands to run before stopping the main process.

      Systemd: ExecStop (before main process kill)
      Launchd: Not supported
      Runit: Not supported (use finish script)

      Warning: Limited support outside systemd.
    '';
  };

  postStop = mkOption {
    type = types.lines;
    default = "";
    example = ''
      rm -rf /tmp/myservice-*
    '';
    description = ''
      Shell commands to run after the service stops.

      Systemd: ExecStopPost
      Launchd: Not supported
      Runit: Maps to finish script

      Runs even if service failed.
    '';
  };

  # Restart behavior
  restart = mkOption {
    type = types.enum [ "always" "on-failure" "on-success" "never" ];
    default = "on-failure";
    example = "always";
    description = ''
      When to restart the service after it exits.

      - always: Restart regardless of exit code
      - on-failure: Restart only on non-zero exit or signal
      - on-success: Restart only on clean exit (exit code 0)
      - never: Do not restart automatically

      Systemd: Maps directly to Restart=
      Launchd: Maps to KeepAlive (bool or SuccessfulExit condition)
      Runit: Always restarts; "never" requires sv down in finish script
    '';
  };

  restartDelay = mkOption {
    type = types.int;
    default = 0;
    example = 5;
    description = ''
      Seconds to wait before restarting the service.

      Systemd: RestartSec=
      Launchd: ThrottleInterval=
      Runit: sleep in finish script (hacky)
    '';
  };

  # I/O redirection
  stdout = mkOption {
    type = types.nullOr types.path;
    default = null;
    example = "/var/log/myservice/stdout.log";
    description = ''
      Path to redirect stdout. If null, uses service manager default.

      Systemd: StandardOutput=file:...
      Launchd: StandardOutPath=
      Runit: Use log/run with svlogd (ignores this option)

      Note: Runit has separate logging architecture.
    '';
  };

  stderr = mkOption {
    type = types.nullOr types.path;
    default = null;
    example = "/var/log/myservice/stderr.log";
    description = ''
      Path to redirect stderr. If null, uses service manager default.

      Systemd: StandardError=file:...
      Launchd: StandardErrorPath=
      Runit: Use log/run with svlogd (ignores this option)
    '';
  };

  # State and runtime directories
  stateDirectory = mkOption {
    type = types.nullOr types.str;
    default = null;
    example = "myservice";
    description = ''
      Name of directory under /var/lib for persistent state.

      Systemd: Creates /var/lib/{name} with proper ownership (StateDirectory=)
      Launchd: Must create manually in preStart
      Runit: Must create manually in run script

      On systemd, this is automatically created with correct user/group
      ownership. On other managers, you must handle creation yourself.
    '';
  };

  runtimeDirectory = mkOption {
    type = types.nullOr types.str;
    default = null;
    example = "myservice";
    description = ''
      Name of directory under /run for runtime state (tmpfs).

      Systemd: Creates /run/{name} with proper ownership (RuntimeDirectory=)
      Launchd: Must create manually (not tmpfs on macOS)
      Runit: Must create manually

      On systemd, this is tmpfs-backed and cleaned on boot.
    '';
  };

  # Additional common directories
  logsDirectory = mkOption {
    type = types.nullOr types.str;
    default = null;
    example = "myservice";
    description = ''
      Name of directory under /var/log for logs.

      Systemd: Creates /var/log/{name} with proper ownership (LogsDirectory=)
      Others: Must create manually
    '';
  };

  cacheDirectory = mkOption {
    type = types.nullOr types.str;
    default = null;
    example = "myservice";
    description = ''
      Name of directory under /var/cache for cached data.

      Systemd: Creates /var/cache/{name} with proper ownership (CacheDirectory=)
      Others: Must create manually
    '';
  };
};
```

---

### Systemd-Specific Extensions

These options are only used when generating systemd units:

```nix
services.<name>.systemd = {
  # Service type
  type = mkOption {
    type = types.enum [ "simple" "exec" "forking" "oneshot" "dbus" "notify" "notify-reload" "idle" ];
    default = "simple";
    description = ''
      Type of service process behavior.

      - simple: Main process specified by ExecStart
      - exec: Like simple, but wait for execve() to succeed
      - forking: Process forks and parent exits
      - oneshot: Like simple, but blocks until completion
      - dbus: Service acquires D-Bus name
      - notify: Service sends readiness notification via sd_notify
      - notify-reload: Like notify, with reload notification support
      - idle: Delays execution until all jobs dispatched
    '';
  };

  # Dependencies
  wants = mkOption {
    type = types.listOf types.str;
    default = [];
    example = [ "network.target" "postgresql.service" ];
    description = ''
      Weak dependencies: these units will be started along with
      this service, but failure doesn't affect this service.
    '';
  };

  requires = mkOption {
    type = types.listOf types.str;
    default = [];
    example = [ "postgresql.service" ];
    description = ''
      Strong dependencies: these units must start successfully,
      or this service will fail to start.
    '';
  };

  requisite = mkOption {
    type = types.listOf types.str;
    default = [];
    description = ''
      Like requires, but doesn't start the dependency if not
      already running (fails immediately instead).
    '';
  };

  bindsTo = mkOption {
    type = types.listOf types.str;
    default = [];
    description = ''
      Very strong dependency: if any of these units stop,
      this service is stopped as well.
    '';
  };

  partOf = mkOption {
    type = types.listOf types.str;
    default = [];
    example = [ "multi-user.target" ];
    description = ''
      When these units are stopped/restarted, this service
      is also stopped/restarted.
    '';
  };

  conflicts = mkOption {
    type = types.listOf types.str;
    default = [];
    description = ''
      If any of these units are started, this service is stopped,
      and vice versa (mutual exclusion).
    '';
  };

  upholds = mkOption {
    type = types.listOf types.str;
    default = [];
    description = ''
      Continuously restart these units if they fail.
    '';
  };

  # Ordering
  after = mkOption {
    type = types.listOf types.str;
    default = [];
    example = [ "network.target" "syslog.service" ];
    description = ''
      Start this service after these units (ordering only,
      not a dependency).
    '';
  };

  before = mkOption {
    type = types.listOf types.str;
    default = [];
    description = ''
      Start this service before these units (ordering only,
      not a dependency).
    '';
  };

  # Reverse dependencies
  wantedBy = mkOption {
    type = types.listOf types.str;
    default = [];
    example = [ "multi-user.target" ];
    description = ''
      Have these units want this service (reverse dependency).
      Commonly used to enable service at boot.
    '';
  };

  requiredBy = mkOption {
    type = types.listOf types.str;
    default = [];
    description = ''
      Have these units require this service (reverse strong dependency).
    '';
  };

  upheldBy = mkOption {
    type = types.listOf types.str;
    default = [];
    description = ''
      Have these units uphold this service (reverse continuous restart).
    '';
  };

  # Advanced restart configuration
  restartPreventExitStatus = mkOption {
    type = types.listOf types.int;
    default = [];
    example = [ 0 1 ];
    description = ''
      List of exit codes that prevent automatic restart.
    '';
  };

  restartForceExitStatus = mkOption {
    type = types.listOf types.int;
    default = [];
    description = ''
      List of exit codes that force restart even if Restart= wouldn't.
    '';
  };

  # Timer integration
  startAt = mkOption {
    type = types.nullOr (types.either types.str (types.listOf types.str));
    default = null;
    example = "daily";
    description = ''
      Automatically create a timer unit to start this service.

      Can be:
      - "hourly", "daily", "weekly", "monthly", "yearly"
      - OnCalendar expression: "Mon,Tue *-*-01..04 12:00:00"
      - List of multiple schedules

      See systemd.time(7) for OnCalendar syntax.
    '';
  };

  # Security and sandboxing
  dynamicUser = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Automatically allocate an ephemeral user for this service.
      Implies several security options and automatic state directory ownership.
    '';
  };

  privateNetwork = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Run in private network namespace (no network access except loopback).
    '';
  };

  privateTmp = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Use private /tmp and /var/tmp (separate from host).
    '';
  };

  privateDevices = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Use private /dev with minimal device nodes.
    '';
  };

  privateUsers = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Run in private user namespace (UID/GID remapping).
    '';
  };

  protectHome = mkOption {
    type = types.oneOf [ types.bool (types.enum [ "read-only" "tmpfs" ]) ];
    default = false;
    description = ''
      Restrict access to /home, /root, and /run/user.
      - false: Full access
      - "read-only": Read-only access
      - "tmpfs" or true: Empty tmpfs (no access)
    '';
  };

  protectSystem = mkOption {
    type = types.oneOf [ types.bool (types.enum [ "full" "strict" ]) ];
    default = false;
    description = ''
      Protect system directories from modification.
      - false: No protection
      - true: /usr and /boot read-only
      - "full": Also /etc read-only
      - "strict": Entire filesystem read-only except specific dirs
    '';
  };

  protectKernelTunables = mkOption {
    type = types.bool;
    default = false;
    description = ''Make /proc/sys, /sys, etc. read-only.'';
  };

  protectKernelModules = mkOption {
    type = types.bool;
    default = false;
    description = ''Block module loading.'';
  };

  protectControlGroups = mkOption {
    type = types.bool;
    default = false;
    description = ''Make cgroup hierarchy read-only.'';
  };

  restrictAddressFamilies = mkOption {
    type = types.nullOr (types.listOf types.str);
    default = null;
    example = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
    description = ''
      Restrict socket address families (whitelist).
      Prefix with ~ for blacklist: [ "~AF_PACKET" "~AF_NETLINK" ]
    '';
  };

  systemCallFilter = mkOption {
    type = types.nullOr (types.listOf types.str);
    default = null;
    example = [ "@system-service" "~@privileged" ];
    description = ''
      Filter system calls (whitelist or blacklist).
      Use @groups like @system-service, @privileged, @network-io.
      Prefix with ~ for blacklist.
    '';
  };

  capabilityBoundingSet = mkOption {
    type = types.nullOr (types.listOf types.str);
    default = null;
    example = [ "CAP_NET_BIND_SERVICE" "CAP_DAC_READ_SEARCH" ];
    description = ''
      Limit capabilities available to the service.
      Prefix with ~ to remove specific capabilities.
    '';
  };

  noNewPrivileges = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Prevent process and children from gaining new privileges
      via setuid, setgid, or capabilities.
    '';
  };

  # Resource limits
  memoryMax = mkOption {
    type = types.nullOr types.str;
    default = null;
    example = "1G";
    description = ''
      Maximum memory (cgroup memory.max). Supports K, M, G suffixes.
    '';
  };

  cpuQuota = mkOption {
    type = types.nullOr types.str;
    default = null;
    example = "50%";
    description = ''
      CPU quota (percentage of one CPU). "200%" = 2 CPUs.
    '';
  };

  tasksMax = mkOption {
    type = types.nullOr types.int;
    default = null;
    example = 1024;
    description = ''
      Maximum number of tasks (threads + processes).
    '';
  };

  # File descriptor limits
  limitNOFILE = mkOption {
    type = types.nullOr types.int;
    default = null;
    example = 65536;
    description = ''
      Maximum number of open file descriptors (RLIMIT_NOFILE).
    '';
  };

  # Raw serviceConfig passthrough
  serviceConfig = mkOption {
    type = types.attrsOf (types.oneOf [ types.str types.int types.bool (types.listOf types.str) ]);
    default = {};
    example = literalExpression ''
      {
        ReadOnlyPaths = [ "/etc" "/usr" ];
        ReadWritePaths = [ "/var/lib/myservice" ];
        UMask = "0027";
        TimeoutStartSec = 60;
      }
    '';
    description = ''
      Raw systemd serviceConfig options. Use this for options
      not exposed in the typed interface above.

      See systemd.service(5) and systemd.exec(5) for all options.
    '';
  };

  # Socket activation
  sockets = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        listenStreams = mkOption {
          type = types.listOf types.str;
          default = [];
          example = [ "0.0.0.0:8080" "/run/myservice.sock" ];
          description = "TCP or Unix socket addresses to listen on.";
        };
        listenDatagrams = mkOption {
          type = types.listOf types.str;
          default = [];
          example = [ "0.0.0.0:5353" ];
          description = "UDP socket addresses to listen on.";
        };
        socketConfig = mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = "Raw socket configuration options.";
        };
      };
    });
    default = {};
    example = literalExpression ''
      {
        main = {
          listenStreams = [ "0.0.0.0:8080" ];
          socketConfig.Accept = "false";
        };
      }
    '';
    description = ''
      Socket activation configuration. Creates socket units
      that start this service on first connection.
    '';
  };

  # Failure handling
  onFailure = mkOption {
    type = types.listOf types.str;
    default = [];
    example = [ "failure-notification@%n.service" ];
    description = ''
      Units to activate when this service fails.
      Useful for alerting or cleanup.
    '';
  };

  onSuccess = mkOption {
    type = types.listOf types.str;
    default = [];
    description = ''
      Units to activate when this service succeeds (oneshot services).
    '';
  };

  # Confinement (inspired by systemd-confinement.nix)
  confinement = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable chroot confinement using systemd's isolation features.
        Creates a minimal root filesystem with only necessary files.
      '';
    };

    mode = mkOption {
      type = types.enum [ "full-apivfs" "chroot-only" ];
      default = "full-apivfs";
      description = ''
        - full-apivfs: Mount /dev, /proc, /sys in chroot
        - chroot-only: Minimal chroot without API filesystems
      '';
    };

    packages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = ''
        Additional packages to include in the chroot.
      '';
    };
  };
};
```

---

### Launchd-Specific Extensions

These options are only used when generating launchd plists:

```nix
services.<name>.launchd = {
  # Launch behavior
  runAtLoad = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Start the service immediately when loaded (at boot or login).
    '';
  };

  keepAlive = mkOption {
    type = types.oneOf [ types.bool (types.submodule {
      options = {
        successfulExit = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Restart only on failure (false) or only on success (true).";
        };
        networkState = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Start when network is available (true).";
        };
        pathState = mkOption {
          type = types.nullOr (types.attrsOf types.bool);
          default = null;
          example = { "/etc/myconfig" = true; };
          description = "Start when paths exist (true) or don't exist (false).";
        };
        otherJobEnabled = mkOption {
          type = types.nullOr (types.attrsOf types.bool);
          default = null;
          example = { "com.example.other" = true; };
          description = "Start when other job is enabled (true) or disabled (false).";
        };
      };
    }) ];
    default = false;
    example = literalExpression ''{ successfulExit = false; }'';
    description = ''
      Restart behavior for the service.

      - true: Always restart
      - false: Never restart
      - { successfulExit = false; }: Restart only on failure
      - { networkState = true; }: Start when network available
    '';
  };

  # Event-driven launch triggers
  watchPaths = mkOption {
    type = types.listOf types.path;
    default = [];
    example = [ "/etc/myservice/config.yaml" "/var/lib/myservice/data" ];
    description = ''
      Start the service when any of these paths are modified.
      Uses FSEvents for efficient monitoring.
    '';
  };

  queueDirectories = mkOption {
    type = types.listOf types.path;
    default = [];
    example = [ "/var/spool/myservice" ];
    description = ''
      Start the service when files appear in these directories.
      Useful for batch processing.
    '';
  };

  # Scheduling
  startInterval = mkOption {
    type = types.nullOr types.int;
    default = null;
    example = 3600;
    description = ''
      Start the service at this interval (in seconds).
      Similar to systemd OnActiveSec.
    '';
  };

  startCalendarInterval = mkOption {
    type = types.nullOr (types.oneOf [
      (types.submodule {
        options = {
          minute = mkOption { type = types.nullOr types.int; default = null; };
          hour = mkOption { type = types.nullOr types.int; default = null; };
          day = mkOption { type = types.nullOr types.int; default = null; };
          weekday = mkOption { type = types.nullOr types.int; default = null; };
          month = mkOption { type = types.nullOr types.int; default = null; };
        };
      })
      (types.listOf (types.submodule {
        options = {
          minute = mkOption { type = types.nullOr types.int; default = null; };
          hour = mkOption { type = types.nullOr types.int; default = null; };
          day = mkOption { type = types.nullOr types.int; default = null; };
          weekday = mkOption { type = types.nullOr types.int; default = null; };
          month = mkOption { type = types.nullOr types.int; default = null; };
        };
      }))
    ]);
    default = null;
    example = literalExpression ''{ hour = 2; minute = 30; }'';
    description = ''
      Start the service at specific calendar times.
      Can be a single time or list of times.

      Note: All times are in local timezone.
    '';
  };

  # Process management
  processType = mkOption {
    type = types.enum [ "Standard" "Background" "Interactive" "Adaptive" ];
    default = "Standard";
    description = ''
      macOS process classification for scheduling.

      - Standard: Normal priority
      - Background: Low priority, throttled
      - Interactive: High priority for UI responsiveness
      - Adaptive: Dynamically adjusted based on user interaction
    '';
  };

  nice = mkOption {
    type = types.nullOr types.int;
    default = null;
    example = 10;
    description = ''
      Process nice value (-20 to 20).
    '';
  };

  # Resource limits
  softResourceLimits = mkOption {
    type = types.attrsOf types.int;
    default = {};
    example = literalExpression ''
      {
        NumberOfFiles = 1024;
        NumberOfProcesses = 256;
      }
    '';
    description = ''
      Soft resource limits (like setrlimit).

      Keys: Core, CPU, Data, FileSize, MemoryLock, NumberOfFiles,
            NumberOfProcesses, ResidentSetSize, Stack
    '';
  };

  hardResourceLimits = mkOption {
    type = types.attrsOf types.int;
    default = {};
    description = ''
      Hard resource limits (like setrlimit).
      Same keys as softResourceLimits.
    '';
  };

  # Socket activation
  sockets = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        sockServiceName = mkOption {
          type = types.str;
          description = "Name to register for socket (used in Accept).";
        };
        sockType = mkOption {
          type = types.enum [ "stream" "dgram" "seqpacket" ];
          default = "stream";
          description = "Socket type (stream=TCP, dgram=UDP).";
        };
        sockProtocol = mkOption {
          type = types.nullOr (types.enum [ "TCP" "UDP" ]);
          default = null;
          description = "Protocol (optional, usually inferred).";
        };
        sockPathName = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Unix socket path.";
        };
        sockNodeName = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "localhost";
          description = "Hostname or IP to bind to.";
        };
        sockPathMode = mkOption {
          type = types.nullOr types.int;
          default = null;
          example = 0600;
          description = "Permissions for Unix socket.";
        };
      };
    });
    default = {};
    example = literalExpression ''
      {
        http = {
          sockServiceName = "http";
          sockNodeName = "localhost";
          sockServiceName = "8080";
        };
      }
    '';
    description = ''
      Socket activation configuration. launchd will listen
      on these sockets and start the service on connection.
    '';
  };

  # Mach services (macOS-specific IPC)
  machServices = mkOption {
    type = types.attrsOf types.bool;
    default = {};
    example = { "com.example.myservice" = true; };
    description = ''
      Mach service names to register.
      Value indicates whether to reset port on service restart.
    '';
  };

  # I/O settings
  standardInPath = mkOption {
    type = types.nullOr types.path;
    default = null;
    description = "Path to use for stdin.";
  };

  # Timeout
  exitTimeout = mkOption {
    type = types.nullOr types.int;
    default = null;
    example = 30;
    description = ''
      Seconds to wait for clean exit before SIGKILL.
      Default is 20 seconds.
    '';
  };

  # Security
  umask = mkOption {
    type = types.nullOr types.int;
    default = null;
    example = 18; # 022 octal
    description = "File creation mask (decimal, not octal).";
  };

  sessionCreate = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Create a new security session (audit session).
      Typically used for user-facing GUI apps.
    '';
  };

  # Additional options
  enableTransactions = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Enable XPC transaction support.
      Prevents exit while transactions are active.
    '';
  };

  abandonProcessGroup = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Don't kill process group when service stops.
      Allows child processes to outlive parent.
    '';
  };

  # Raw plist passthrough
  extraConfig = mkOption {
    type = types.attrs;
    default = {};
    example = literalExpression ''
      {
        LegacyTimers = true;
        ThrottleInterval = 10;
      }
    '';
    description = ''
      Additional launchd.plist keys not covered above.
      See launchd.plist(5) for all options.
    '';
  };
};
```

---

### Runit-Specific Extensions

These options are only used when generating runit service directories:

```nix
services.<name>.runit = {
  # Logging configuration
  logScript = mkOption {
    type = types.lines;
    default = ''
      exec svlogd -tt /var/log/${name}
    '';
    example = ''
      exec svlogd -tt -r 10000 -n 10 /var/log/myservice
    '';
    description = ''
      Contents of log/run script for service logging.

      Default uses svlogd with:
      - -tt: Prefix with TAI64N timestamps
      - Log directory: /var/log/<servicename>

      Common svlogd options:
      - -r SIZE: Rotate when SIZE bytes (default 1000000)
      - -n NUM: Keep NUM old log files
      - -N NUM: Keep at most NUM old log files
      - -s SIZE: Min file size before processing
      - -l NUM: Replace control chars with at most NUM dots

      The script should exec the logger (don't run in background).
    '';
  };

  enableLogging = mkOption {
    type = types.bool;
    default = true;
    description = ''
      Whether to create a log/run script.
      If false, service output goes to runsv output.
    '';
  };

  # Health check
  checkScript = mkOption {
    type = types.lines;
    default = "";
    example = ''
      exec ${pkgs.curl}/bin/curl -f http://localhost:8080/health
    '';
    description = ''
      Contents of check script for health monitoring.

      Used by `sv check <service>` to verify service is healthy.
      Should exit 0 if healthy, non-zero if unhealthy.

      Commonly used to:
      - Check if process is responding
      - Verify API endpoints
      - Test database connectivity
    '';
  };

  # Cleanup on exit
  finishScript = mkOption {
    type = types.lines;
    default = "";
    example = ''
      echo "Service exited with code $1, signal $2"
      rm -rf /tmp/myservice-*

      # Prevent restart on clean exit
      [ "$1" = "0" ] && sv down .
    '';
    description = ''
      Contents of finish script, run when service exits.

      Arguments:
      - $1: Exit code (or 0 if killed by signal)
      - $2: Signal number (or -1 if exited normally)

      Use cases:
      - Cleanup temporary files
      - Send notifications
      - Prevent restart on certain conditions (sv down .)
      - Implement restart delays (sleep N)

      The service will restart after finish completes,
      unless you run `sv down .` or run script exits 0.
    '';
  };

  # Service control
  downSignal = mkOption {
    type = types.str;
    default = "TERM";
    example = "HUP";
    description = ''
      Signal to send when stopping service (sv down).
      Default is SIGTERM. Common: TERM, HUP, INT, QUIT.
    '';
  };

  # Environment directory
  envDir = mkOption {
    type = types.nullOr types.path;
    default = null;
    example = "/etc/myservice/env";
    description = ''
      Path to environment directory for chpst -e.
      Each file in directory becomes an environment variable.

      Example structure:
        /etc/myservice/env/
          DATABASE_URL (file containing "postgres://...")
          API_KEY (file containing "secret123")

      If null, environment is set inline in run script.
    '';
  };

  # chpst options
  chpstOpts = mkOption {
    type = types.listOf types.str;
    default = [];
    example = [ "-m 100000000" "-o 1024" ];
    description = ''
      Additional chpst options for resource limits and control.

      Common options:
      - -u USER[:GROUP] - Run as user/group (handled automatically)
      - -U USER[:GROUP] - Set $UID, $GID env vars
      - -e DIR - Load environment from directory
      - -/ DIR - Chroot to directory
      - -n NICE - Nice value
      - -l LOCK - Limit to one instance (lock file)
      - -L LOCK - Wait for lock instead of failing
      - -m BYTES - Limit data segment (RLIMIT_DATA)
      - -d BYTES - Limit data segment (RLIMIT_DATA)
      - -o N - Limit open files (RLIMIT_NOFILE)
      - -p N - Limit processes (RLIMIT_NPROC)
      - -f BYTES - Limit file size (RLIMIT_FSIZE)
      - -c BYTES - Limit core size (RLIMIT_CORE)
      - -r BYTES - Limit resident memory (RLIMIT_RSS)
      - -s BYTES - Limit stack (RLIMIT_STACK)
      - -t SECS - Limit CPU time (RLIMIT_CPU)

      See chpst(8) for details.
    '';
  };

  # Additional run script setup
  preExec = mkOption {
    type = types.lines;
    default = "";
    example = ''
      # Wait for network
      sv check network-wait || exit 1

      # Ensure directories exist
      mkdir -p /var/lib/myservice

      # Set up environment
      export CONFIG_FILE=/etc/myservice/config.yaml
    '';
    description = ''
      Shell commands to run in run script before exec'ing main command.

      Use this for:
      - Waiting for dependencies (sv check other-service)
      - Creating directories
      - Setting up environment
      - One-time initialization

      Note: This runs every time the service starts, so keep it fast.
    '';
  };

  # Raw run script override
  runScript = mkOption {
    type = types.nullOr types.lines;
    default = null;
    example = ''
      #!/bin/sh
      exec 2>&1
      exec chpst -u myuser /path/to/myapp --config /etc/myapp/config
    '';
    description = ''
      Complete override of the run script.
      If set, all other options (command, args, user, etc.) are ignored
      for the run script (but still used for logging/finish scripts).

      Use this for complete control or complex startup sequences.

      The script MUST:
      - Be executable (#!/bin/sh shebang)
      - exec the final process (no forking)
      - Redirect stderr to stdout (exec 2>&1)
    '';
  };
};
```

---

### BSD rc.d-Specific Extensions

These options are only used when generating BSD rc.d scripts:

```nix
services.<name>.rcd = {
  # Dependency declarations (FreeBSD, NetBSD, DragonFly BSD only - not OpenBSD)
  provide = mkOption {
    type = types.listOf types.str;
    default = [ name ];
    example = [ "dns" "nscd" ];
    description = ''
      Service names provided by this script (PROVIDE keyword).
      Used by other scripts in their REQUIRE declarations.

      Note: Not used on OpenBSD (no dependency system).
    '';
  };

  require = mkOption {
    type = types.listOf types.str;
    default = [];
    example = [ "NETWORKING" "syslog" "DAEMON" ];
    description = ''
      Services that must start before this one (REQUIRE keyword).
      These are hard dependencies - script won't run until available.

      Common keywords: NETWORKING, DAEMON, LOGIN, FILESYSTEMS, syslog

      Note: Not used on OpenBSD (no dependency system).
    '';
  };

  before = mkOption {
    type = types.listOf types.str;
    default = [];
    example = [ "DAEMON" "mail" ];
    description = ''
      Services that should start after this one (BEFORE keyword).
      This is an inverse dependency declaration.

      Note: Not used on OpenBSD (no dependency system).
    '';
  };

  keywords = mkOption {
    type = types.listOf (types.enum [ "shutdown" "nojail" "nostart" ]);
    default = [];
    example = [ "shutdown" ];
    description = ''
      Special rcorder keywords (KEYWORD line).

      - shutdown: Service wants clean shutdown
      - nojail: Don't run in FreeBSD jails
      - nostart: Don't auto-start at boot

      Note: Not used on OpenBSD (no rcorder).
    '';
  };

  # rc.conf variable name
  rcvar = mkOption {
    type = types.str;
    default = "${name}_enable";
    example = "nginx_enable";
    description = ''
      Name of rc.conf variable for enabling/disabling service.
      Convention: ${name}_enable

      Set to "YES" in rc.conf to enable service.
    '';
  };

  # Process management
  commandInterpreter = mkOption {
    type = types.nullOr types.str;
    default = null;
    example = "/usr/local/bin/python3.9";
    description = ''
      Actual process name for script-based daemons.
      Helps rc.subr identify the correct process in ps output.

      Use when command is a script, not a binary.
    '';
  };

  procname = mkOption {
    type = types.nullOr types.str;
    default = null;
    example = "nginx: master process";
    description = ''
      Override process name for stop/status checks.
      Used when the running process name differs from command.

      FreeBSD/NetBSD: Used for process lookup
      OpenBSD: Use pexp instead
    '';
  };

  pidfile = mkOption {
    type = types.nullOr types.path;
    default = null;
    example = "/var/run/myservice.pid";
    description = ''
      Path to PID file for reliable process tracking.
      Checked before starting to prevent duplicate instances.

      FreeBSD/NetBSD/DragonFly: Preferred method
      OpenBSD: pexp is used instead
    '';
  };

  # Signals (FreeBSD/NetBSD/DragonFly)
  sigStop = mkOption {
    type = types.str;
    default = "TERM";
    example = "QUIT";
    description = ''
      Signal to send when stopping service (without SIG prefix).
      Common values: TERM, INT, HUP, QUIT, KILL

      FreeBSD/NetBSD: sig_stop variable
      OpenBSD: rc_stop_signal variable
    '';
  };

  sigReload = mkOption {
    type = types.str;
    default = "HUP";
    example = "USR1";
    description = ''
      Signal for configuration reload (without SIG prefix).

      FreeBSD/NetBSD: sig_reload variable
      OpenBSD: Default for rc_reload
    '';
  };

  # rc.conf flags
  flags = mkOption {
    type = types.str;
    default = "";
    example = "-v -c /etc/myservice.conf";
    description = ''
      Default command-line flags for the service.
      Stored in rc.conf as ${name}_flags.

      User can override in /etc/rc.conf.local or /etc/rc.conf.
    '';
  };

  # Prerequisites (FreeBSD/NetBSD/DragonFly)
  requiredFiles = mkOption {
    type = types.listOf types.path;
    default = [];
    example = [ "/etc/myservice/config.yaml" "/etc/myservice/secret.key" ];
    description = ''
      Files that must exist before service starts.
      Start fails if any are missing (unless using forcestart).

      FreeBSD/NetBSD: required_files variable
      OpenBSD: Manual check in rc_pre
    '';
  };

  requiredDirs = mkOption {
    type = types.listOf types.path;
    default = [];
    example = [ "/var/lib/myservice" "/var/run/myservice" ];
    description = ''
      Directories that must exist before service starts.

      FreeBSD/NetBSD: required_dirs variable
      OpenBSD: Manual check in rc_pre
    '';
  };

  requiredVars = mkOption {
    type = types.listOf types.str;
    default = [];
    example = [ "myservice_config" "myservice_database" ];
    description = ''
      rc.conf variables that must be set before service starts.

      FreeBSD/NetBSD: required_vars variable
      OpenBSD: Not available
    '';
  };

  # Custom commands (FreeBSD/NetBSD/DragonFly)
  extraCommands = mkOption {
    type = types.listOf types.str;
    default = [];
    example = [ "reload" "configtest" "upgrade" ];
    description = ''
      Additional commands beyond start/stop/restart/status.
      Each requires a corresponding ${command}_cmd function.

      FreeBSD/NetBSD: extra_commands variable
      OpenBSD: Define via rc_reload, etc.
    '';
  };

  # Command implementations (all BSD variants)
  startCmd = mkOption {
    type = types.nullOr types.lines;
    default = null;
    example = ''
      echo "Starting custom service"
      ${command} ${args} &
    '';
    description = ''
      Custom start command implementation.
      Overrides default rc.subr start logic.

      FreeBSD/NetBSD: start_cmd variable
      OpenBSD: rc_start function
    '';
  };

  stopCmd = mkOption {
    type = types.nullOr types.lines;
    default = null;
    description = ''
      Custom stop command implementation.
      Set to ":" (no-op) if no cleanup needed.

      FreeBSD/NetBSD: stop_cmd variable
      OpenBSD: rc_stop function
    '';
  };

  reloadCmd = mkOption {
    type = types.nullOr types.lines;
    default = null;
    example = ''
      kill -HUP `cat $pidfile`
    '';
    description = ''
      Custom reload command implementation.
      Must add "reload" to extraCommands.

      FreeBSD/NetBSD: reload_cmd variable
      OpenBSD: rc_reload function
    '';
  };

  statusCmd = mkOption {
    type = types.nullOr types.lines;
    default = null;
    description = ''
      Custom status check implementation.
      Overrides default process lookup.

      FreeBSD/NetBSD: status_cmd variable
      OpenBSD: rc_check function
    '';
  };

  # FreeBSD-specific features
  loginClass = mkOption {
    type = types.str;
    default = "daemon";
    example = "webserver";
    description = ''
      Login class for resource limits (FreeBSD/NetBSD only).
      Defined in /etc/login.conf.

      FreeBSD: ${name}_login_class variable
      Not available on OpenBSD/DragonFly
    '';
  };

  limits = mkOption {
    type = types.nullOr types.str;
    default = null;
    example = "memoryuse 1G maxproc 256";
    description = ''
      Resource limits string for limits(1) (FreeBSD only).
      Applied via start_precmd.

      Example: "memoryuse 1G openfiles 65536"

      FreeBSD: ${name}_limits variable
      NetBSD: Use login.conf
      OpenBSD: Use login.conf classes
    '';
  };

  serviceJail = mkOption {
    type = types.nullOr (types.either types.bool (types.enum [ "net_basic" "net_raw" ""]));
    default = null;
    example = "net_basic";
    description = ''
      Service jail compatibility options (FreeBSD only).

      - false or "NO": Service cannot run in jails
      - true or "": Works in jails without special requirements
      - "net_basic": Needs basic networking in jail
      - "net_raw": Needs raw sockets in jail

      FreeBSD: ${name}_svcj and ${name}_svcj_options
      Not available on other BSDs
    '';
  };

  # OpenBSD-specific features
  pexp = mkOption {
    type = types.nullOr types.str;
    default = null;
    example = "nginx: master process";
    description = ''
      Regex pattern for pgrep/pkill to locate process (OpenBSD only).
      Used instead of pidfile on OpenBSD.

      Must match the process as shown in ps output.

      OpenBSD: pexp variable
      Not used on FreeBSD/NetBSD/DragonFly (use pidfile)
    '';
  };

  timeout = mkOption {
    type = types.int;
    default = 30;
    example = 60;
    description = ''
      Timeout in seconds for start/stop/reload operations.

      OpenBSD: daemon_timeout variable (default 30)
      FreeBSD/NetBSD: Use rc.conf timeouts
    '';
  };

  background = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Force daemon to start in background (OpenBSD only).

      OpenBSD: rc_bg=YES
      Not needed on FreeBSD/NetBSD (handled by daemon type)
    '';
  };

  # Profile support (FreeBSD only)
  profiles = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        flags = mkOption {
          type = types.str;
          default = "";
          description = "Profile-specific flags";
        };
        pidfile = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Profile-specific PID file path";
        };
        requiredFiles = mkOption {
          type = types.listOf types.path;
          default = [];
          description = "Profile-specific required files";
        };
      };
    });
    default = {};
    example = literalExpression ''
      {
        production = {
          flags = "-c /etc/nginx/nginx-prod.conf";
          pidfile = "/var/run/nginx-prod.pid";
        };
        staging = {
          flags = "-c /etc/nginx/nginx-staging.conf";
          pidfile = "/var/run/nginx-staging.pid";
        };
      }
    '';
    description = ''
      Multiple service profiles for running multiple instances (FreeBSD only).

      Each profile gets its own set of rc.conf variables.
      Managed via: service ${name} start production

      FreeBSD: ${name}_profiles variable
      Not available on other BSDs
    '';
  };

  # Pre/post hooks (FreeBSD/NetBSD/DragonFly)
  startPrecmd = mkOption {
    type = types.lines;
    default = "";
    example = ''
      echo "Preparing to start service"
      mkdir -p /var/run/myservice
    '';
    description = ''
      Commands to run before start operation.
      Non-zero exit prevents service from starting.

      FreeBSD/NetBSD: start_precmd variable
      OpenBSD: rc_pre function
    '';
  };

  startPostcmd = mkOption {
    type = types.lines;
    default = "";
    description = ''
      Commands to run after successful start.
      Only runs if start succeeded.

      FreeBSD/NetBSD: start_postcmd variable
      OpenBSD: rc_post function
    '';
  };

  stopPrecmd = mkOption {
    type = types.lines;
    default = "";
    description = ''
      Commands to run before stop operation.

      FreeBSD/NetBSD: stop_precmd variable
      OpenBSD: rc_pre function (for stop)
    '';
  };

  stopPostcmd = mkOption {
    type = types.lines;
    default = "";
    example = ''
      rm -rf /tmp/myservice-*
    '';
    description = ''
      Commands to run after service stops.
      Runs even if stop failed.

      FreeBSD/NetBSD: stop_postcmd variable
      OpenBSD: rc_post function (for stop)
    '';
  };

  # Raw script override
  script = mkOption {
    type = types.nullOr types.lines;
    default = null;
    example = ''
      #!/bin/sh
      # PROVIDE: myservice
      # REQUIRE: NETWORKING

      . /etc/rc.subr

      name="myservice"
      rcvar=myservice_enable
      command="/usr/local/bin/myapp"

      load_rc_config $name
      run_rc_command "$1"
    '';
    description = ''
      Complete override of the rc.d script.
      If set, all other options are ignored for the main script.

      Use for complete control or when the abstraction doesn't fit.

      Must include:
      - #!/bin/sh shebang
      - PROVIDE/REQUIRE/BEFORE comments (except OpenBSD)
      - . /etc/rc.subr (FreeBSD/NetBSD/DragonFly)
      - load_rc_config and run_rc_command calls
    '';
  };
};
```

---

## Implementation Strategy

### Module System Architecture

```nix
{ config, lib, pkgs, ... }:

let
  inherit (lib) mkOption types mkIf;

  # Detect which service manager we're using
  serviceManager = if config.systemd.services != null then "systemd"
                  else if config.launchd.agents != null then "launchd"
                  else if config.runit.services != null then "runit"
                  else if config.rcd.services != null then "rcd"
                  else "unknown";

  # Detect BSD variant
  bsdVariant =
    if pkgs.stdenv.isFreeBSD then "freebsd"
    else if pkgs.stdenv.isOpenBSD then "openbsd"
    else if pkgs.stdenv.isNetBSD then "netbsd"
    else if pkgs.stdenv.isDragonFlyBSD then "dragonfly"
    else null;

  # Service module type
  serviceModule = { name, config, ... }: {
    options = {
      # Common options (defined above)
      enable = mkOption { ... };
      description = mkOption { ... };
      # ... etc

      # Manager-specific namespaces
      systemd = mkOption {
        type = types.submodule systemdOptions;
        default = {};
      };
      launchd = mkOption {
        type = types.submodule launchdOptions;
        default = {};
      };
      runit = mkOption {
        type = types.submodule runitOptions;
        default = {};
      };
      rcd = mkOption {
        type = types.submodule rcdOptions;
        default = {};
      };
    };

    config = {
      # Validation
      assertions = [
        {
          assertion = serviceManager == "systemd" || config.systemd == {};
          message = "Service ${name} uses systemd options but systemd is not available";
        }
        # ... more assertions
      ];

      # Warnings for unsupported features
      warnings =
        lib.optional (serviceManager != "systemd" && config.postStart != "")
          "Service ${name}: postStart not supported on ${serviceManager}"
        ++ lib.optional (serviceManager == "runit" && config.restart == "on-success")
          "Service ${name}: runit doesn't support restart=on-success"
        # ... more warnings
      ;
    };
  };

in {
  options = {
    services = mkOption {
      type = types.attrsOf (types.submodule serviceModule);
      default = {};
      description = "Unified service definitions";
    };
  };

  config = {
    # Generate systemd units
    systemd.services = lib.mapAttrs (name: svc:
      mkIf (svc.enable && serviceManager == "systemd") {
        description = svc.description;
        wantedBy = svc.systemd.wantedBy;
        after = svc.systemd.after;
        # ... translate all options
        serviceConfig = {
          ExecStart = "${svc.command} ${lib.escapeShellArgs svc.args}";
          User = svc.user;
          Group = svc.group;
          WorkingDirectory = svc.workingDirectory;
          Environment = lib.mapAttrsToList (k: v: "${k}=${v}") svc.environment;
          # ... more translations
        } // svc.systemd.serviceConfig;
      }
    ) config.services;

    # Generate launchd plists
    launchd.daemons = lib.mapAttrs (name: svc:
      mkIf (svc.enable && serviceManager == "launchd") {
        script = ''
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
                   "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>Label</key>
            <string>org.nixos.${name}</string>
            <key>ProgramArguments</key>
            <array>
              <string>${svc.command}</string>
              ${lib.concatMapStrings (arg: "<string>${arg}</string>\n") svc.args}
            </array>
            ${lib.optionalString (svc.user != "root") ''
              <key>UserName</key>
              <string>${svc.user}</string>
            ''}
            <!-- ... more translations -->
          </dict>
          </plist>
        '';
      }
    ) config.services;

    # Generate runit service directories
    runit.services = lib.mapAttrs (name: svc:
      mkIf (svc.enable && serviceManager == "runit") {
        run = ''
          #!/bin/sh
          exec 2>&1

          ${svc.runit.preExec}
          ${svc.preStart}

          ${lib.optionalString (svc.environment != {}) ''
            # Set environment
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "export ${k}='${v}'") svc.environment)}
          ''}

          ${lib.optionalString (svc.path != []) ''
            export PATH="${lib.makeBinPath svc.path}:$PATH"
          ''}

          ${lib.optionalString (svc.workingDirectory != null) ''
            cd '${svc.workingDirectory}'
          ''}

          exec chpst -u ${svc.user}:${svc.group} \
            ${lib.concatStringsSep " " svc.runit.chpstOpts} \
            ${svc.command} ${lib.escapeShellArgs svc.args}
        '';

        log = mkIf svc.runit.enableLogging svc.runit.logScript;
        finish = mkIf (svc.runit.finishScript != "") svc.runit.finishScript;
        check = mkIf (svc.runit.checkScript != "") svc.runit.checkScript;
      }
    ) config.services;
  };
}
```

### Translation Rules

#### Common → systemd

```nix
{
  command + args → ExecStart
  user → User
  group → Group
  environment → Environment
  path → PATH in Environment
  workingDirectory → WorkingDirectory
  preStart → ExecStartPre (separate script unit)
  postStart → ExecStartPost
  preStop → ExecStop (before termination)
  postStop → ExecStopPost
  restart "always" → Restart=always
  restart "on-failure" → Restart=on-failure
  restart "never" → Restart=no
  restartDelay → RestartSec
  stdout → StandardOutput=file:<path>
  stderr → StandardError=file:<path>
  stateDirectory → StateDirectory (auto-creates /var/lib/<name>)
  runtimeDirectory → RuntimeDirectory (auto-creates /run/<name>)
}
```

#### Common → launchd

```nix
{
  command + args → ProgramArguments array
  user → UserName
  group → GroupName
  environment → EnvironmentVariables dict
  path → PATH in EnvironmentVariables
  workingDirectory → WorkingDirectory
  preStart → Wrapper script in ProgramArguments (hacky)
  postStart → Not supported (warning)
  preStop → Not supported (warning)
  postStop → Not supported (warning)
  restart "always" → KeepAlive = true
  restart "on-failure" → KeepAlive.SuccessfulExit = false
  restart "never" → KeepAlive = false
  restartDelay → ThrottleInterval
  stdout → StandardOutPath
  stderr → StandardErrorPath
  stateDirectory → Manual (create in wrapper script)
  runtimeDirectory → Manual (create in wrapper script)
}
```

#### Common → runit

```nix
{
  command + args → exec line in run script
  user → chpst -u <user>:<group>
  environment → export statements in run script
  path → PATH export in run script
  workingDirectory → cd in run script
  preStart → Inline in run script before exec
  postStart → Not supported (warning)
  preStop → Not supported (warning)
  postStop → finish script
  restart "always" → Default behavior
  restart "on-failure" → Default behavior
  restart "never" → sv down in finish script if exit 0
  restartDelay → sleep in finish script
  stdout → svlogd in log/run
  stderr → svlogd in log/run (combined with stdout)
  stateDirectory → mkdir -p in run script
  runtimeDirectory → mkdir -p in run script
}
```

#### Common → BSD rc.d

```nix
{
  command + args → command + rc.conf ${name}_flags
  user → ${name}_user in rc.conf
  group → ${name}_group in rc.conf
  environment → export statements in start_precmd
  path → PATH export in start_precmd
  workingDirectory → cd in start_precmd
  preStart → start_precmd function
  postStart → start_postcmd function
  preStop → stop_precmd function
  postStop → stop_postcmd function
  restart "always" → Not supported (warning - no supervision)
  restart "on-failure" → Not supported (warning - no supervision)
  restart "never" → Default behavior (no supervision)
  restartDelay → Not supported (no supervision)
  stateDirectory → mkdir -p in start_precmd (manual)
  runtimeDirectory → mkdir -p in start_precmd (manual)
  stdout → Redirection in rc.d script or logger(1)
  stderr → Redirection in rc.d script or logger(1)
  description → desc variable (FreeBSD/NetBSD) or comment (OpenBSD)
}
```

### Validation Rules

```nix
# Error on truly incompatible options
assertions = [
  {
    assertion = !svc.systemd.privateNetwork || serviceManager == "systemd";
    message = "privateNetwork requires systemd (not available on ${serviceManager})";
  }
  {
    assertion = !svc.launchd.watchPaths || serviceManager == "launchd";
    message = "watchPaths requires launchd (not available on ${serviceManager})";
  }
  {
    assertion = svc.restart != "on-success" || serviceManager != "runit";
    message = "runit doesn't support restart=on-success (always restarts on failure)";
  }
  {
    assertion = !svc.rcd.serviceJail || bsdVariant == "freebsd";
    message = "serviceJail only supported on FreeBSD";
  }
  {
    assertion = svc.rcd.profiles == {} || bsdVariant == "freebsd";
    message = "Service profiles only supported on FreeBSD";
  }
  {
    assertion = !svc.rcd.pexp || bsdVariant == "openbsd";
    message = "pexp is OpenBSD-specific (use pidfile on FreeBSD/NetBSD/DragonFly)";
  }
  {
    assertion = !(bsdVariant == "openbsd" && svc.rcd.require != []);
    message = "OpenBSD has no dependency system (REQUIRE not supported)";
  }
];

# Warn on features that won't work
warnings = [
  (lib.optional (serviceManager != "systemd" && svc.postStart != "")
    "${name}: postStart only works on systemd")

  (lib.optional (serviceManager == "runit" && svc.stateDirectory != null)
    "${name}: stateDirectory not auto-created on runit (manual setup required)")

  (lib.optional (serviceManager != "launchd" && svc.launchd.watchPaths != [])
    "${name}: watchPaths only works on launchd")

  (lib.optional (serviceManager == "rcd" && svc.stateDirectory != null)
    "${name}: stateDirectory not auto-created on BSD rc.d (manual setup required in start_precmd)")

  (lib.optional (serviceManager == "rcd" && svc.restart != "never")
    "${name}: BSD rc.d doesn't provide automatic restart supervision")

  (lib.optional (serviceManager == "rcd" && svc.restartDelay != 0)
    "${name}: restartDelay not supported on BSD rc.d (no supervision)")

  (lib.optional (bsdVariant == "openbsd" && svc.rcd.pidfile != null)
    "${name}: OpenBSD uses pexp instead of pidfile for process matching")

  (lib.optional (bsdVariant != "freebsd" && svc.rcd.limits != null)
    "${name}: limits only supported on FreeBSD (use login.conf on other BSDs)")
];
```

### Helper Functions

```nix
lib.services = {
  # Common pattern: network-dependent service
  networkAfter = lib.optionalAttrs (serviceManager == "systemd") {
    systemd.after = [ "network.target" ];
  };

  # Common pattern: basic sandboxing
  basicSandbox = lib.optionalAttrs (serviceManager == "systemd") {
    systemd = {
      dynamicUser = true;
      privateNetwork = false;
      privateTmp = true;
      protectHome = true;
      protectSystem = "strict";
      protectKernelTunables = true;
      restrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      noNewPrivileges = true;
    };
  };

  # Common pattern: daily timer
  daily = time: lib.optionalAttrs (serviceManager == "systemd") {
    systemd.startAt = "daily";
  } // lib.optionalAttrs (serviceManager == "launchd") {
    launchd.startCalendarInterval = { hour = time; minute = 0; };
  };
};
```

---

## Example Configurations

### 1. Simple Web Server

```nix
services.nginx = {
  enable = true;
  description = "Nginx HTTP server";

  command = "${pkgs.nginx}/bin/nginx";
  args = [ "-c" "/etc/nginx/nginx.conf" "-g" "daemon off;" ];

  user = "nginx";
  group = "nginx";

  stateDirectory = "nginx";
  runtimeDirectory = "nginx";
  logsDirectory = "nginx";

  preStart = ''
    # Test configuration
    ${pkgs.nginx}/bin/nginx -t -c /etc/nginx/nginx.conf
  '';

  restart = "always";

  # systemd-specific: sandboxing
  systemd = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    # Basic security
    privateTmp = true;
    protectHome = true;
    protectSystem = "strict";

    # Allow binding to port 80
    capabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];

    # Increase file descriptor limit
    limitNOFILE = 65536;
  };

  # launchd-specific: run at load
  launchd = {
    runAtLoad = true;
    keepAlive = true;
    processType = "Standard";
  };

  # runit-specific: health check
  runit = {
    checkScript = ''
      exec ${pkgs.curl}/bin/curl -f http://localhost:80/ > /dev/null
    '';
  };
};
```

### 2. Database with Dependencies

```nix
services.postgresql = {
  enable = true;
  description = "PostgreSQL database server";

  command = "${pkgs.postgresql}/bin/postgres";
  args = [ "-D" "/var/lib/postgresql/data" ];

  user = "postgres";
  group = "postgres";

  environment = {
    PGDATA = "/var/lib/postgresql/data";
    LANG = "en_US.UTF-8";
  };

  stateDirectory = "postgresql";
  runtimeDirectory = "postgresql";

  preStart = ''
    # Initialize database if needed
    if [ ! -d /var/lib/postgresql/data ]; then
      ${pkgs.postgresql}/bin/initdb -D /var/lib/postgresql/data
    fi
  '';

  postStop = ''
    echo "PostgreSQL stopped at $(date)" >> /var/log/postgresql/shutdown.log
  '';

  restart = "on-failure";
  restartDelay = 5;

  systemd = {
    wantedBy = [ "multi-user.target" ];

    # Require storage to be mounted
    requires = [ "var-lib-postgresql.mount" ];
    after = [ "var-lib-postgresql.mount" "network.target" ];

    # Resource limits
    memoryMax = "4G";
    limitNOFILE = 65536;

    # Moderate sandboxing (needs network, some system access)
    privateTmp = true;
    protectHome = true;
    noNewPrivileges = true;

    # Custom stop signal
    serviceConfig = {
      KillMode = "mixed";
      KillSignal = "SIGINT";
      TimeoutStopSec = 120;
    };
  };

  launchd = {
    runAtLoad = true;
    keepAlive.successfulExit = false; # Restart on failure

    softResourceLimits = {
      NumberOfFiles = 65536;
    };

    # Start after disk mount (approximation)
    keepAlive.pathState = {
      "/var/lib/postgresql" = true;
    };
  };

  runit = {
    preExec = ''
      # Wait for filesystem
      until [ -d /var/lib/postgresql ]; do
        sleep 1
      done
    '';

    finishScript = ''
      echo "PostgreSQL exited: code=$1 signal=$2" >&2
      # Always restart unless cleanly shut down
      [ "$1" = "0" ] && [ "$2" = "-1" ] && sv down .
    '';
  };
};
```

### 3. Scheduled Backup Service

```nix
services.backup = {
  enable = true;
  description = "Nightly database backup";

  command = "${pkgs.bash}/bin/bash";
  args = [ "-c" "pg_dump mydb > /var/backups/mydb-$(date +%Y%m%d).sql" ];

  user = "backup";
  group = "backup";

  path = [ pkgs.postgresql pkgs.gzip ];

  environment = {
    PGHOST = "/run/postgresql";
  };

  # This is a one-shot task
  systemd = {
    type = "oneshot";

    # Run daily at 2:30 AM
    startAt = "02:30";

    # Require PostgreSQL to be running
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];

    # Cleanup old backups
    serviceConfig.ExecStartPost = "${pkgs.bash}/bin/bash -c 'find /var/backups -name mydb-*.sql -mtime +30 -delete'";
  };

  launchd = {
    # Run daily at 2:30 AM
    startCalendarInterval = {
      hour = 2;
      minute = 30;
    };

    # Don't keep running
    keepAlive = false;
  };

  runit = {
    # Runit doesn't have built-in scheduling
    # Note: Would need a separate cron service or timer
    runScript = ''
      #!/bin/sh
      exec 2>&1
      echo "Note: Scheduled services require external cron on runit"
      exit 1
    '';
  };
};
```

### 4. Socket-Activated Service

```nix
services.myapi = {
  enable = true;
  description = "My API server (socket-activated)";

  command = "${pkgs.myapi}/bin/myapi";
  args = [ "--systemd-socket" ];

  user = "myapi";
  group = "myapi";

  stateDirectory = "myapi";

  restart = "on-failure";

  systemd = {
    # Socket activation
    sockets.main = {
      listenStreams = [ "0.0.0.0:8080" "/run/myapi.sock" ];
      socketConfig = {
        Accept = "false";
        MaxConnections = 1000;
      };
    };

    # Don't start automatically, only via socket
    wantedBy = []; # Empty!

    # Basic sandboxing
    dynamicUser = true;
    privateTmp = true;
    privateNetwork = false; # Need network for API
    protectHome = true;
    protectSystem = "strict";

    # Allow access to state directory
    serviceConfig = {
      ReadWritePaths = [ "/var/lib/myapi" ];
    };
  };

  launchd = {
    # Socket activation
    sockets.http = {
      sockServiceName = "http";
      sockType = "stream";
      sockNodeName = "localhost";
      sockServiceName = "8080";
    };

    sockets.unix = {
      sockServiceName = "myapi";
      sockType = "stream";
      sockPathName = "/var/run/myapi.sock";
      sockPathMode = 0600;
    };

    # Launch on demand via sockets
    runAtLoad = false;
    keepAlive = false;
  };

  runit = {
    # No socket activation support
    # Service must listen on its own
    preExec = ''
      echo "Warning: Socket activation not supported on runit" >&2
      echo "Service will bind ports directly" >&2
    '';
  };
};
```

### 5. High-Security Sandboxed Service

```nix
services.untrusted-processor = {
  enable = true;
  description = "Untrusted data processor (heavily sandboxed)";

  command = "${pkgs.myprocessor}/bin/processor";
  args = [ "--input-dir" "/var/lib/processor/input" "--output-dir" "/var/lib/processor/output" ];

  user = "processor";
  group = "processor";

  stateDirectory = "processor";

  restart = "on-failure";

  systemd = {
    wantedBy = [ "multi-user.target" ];

    # Maximum sandboxing
    dynamicUser = true;
    privateNetwork = true; # No network access
    privateTmp = true;
    privateDevices = true;
    privateUsers = true;

    protectHome = true;
    protectSystem = "strict";
    protectKernelTunables = true;
    protectKernelModules = true;
    protectKernelLogs = true;
    protectControlGroups = true;
    protectClock = true;

    # Strict filesystem access
    serviceConfig = {
      # Everything read-only except state dir
      ReadOnlyPaths = [ "/" ];
      ReadWritePaths = [ "/var/lib/processor" ];

      # No access to sensitive paths
      InaccessiblePaths = [
        "/root"
        "/home"
        "/etc/shadow"
        "/etc/gshadow"
      ];

      # Temporary filesystem over /tmp
      TemporaryFileSystem = [ "/tmp" ];
    };

    # No capabilities
    capabilityBoundingSet = [];
    noNewPrivileges = true;

    # Strict syscall filtering
    systemCallFilter = [
      "@system-service"  # Allow basic service syscalls
      "~@privileged"     # Block privileged operations
      "~@resources"      # Block resource control syscalls
      "~@obsolete"       # Block obsolete syscalls
      "~@debug"          # Block debugging syscalls
      "~@mount"          # Block mount operations
      "~@swap"           # Block swap operations
      "~@reboot"         # Block reboot
      "~@module"         # Block kernel module operations
      "~@raw-io"         # Block raw I/O
    ];

    restrictAddressFamilies = []; # No sockets at all
    restrictNamespaces = true;
    restrictRealtime = true;
    restrictSUIDSGID = true;
    memoryDenyWriteExecute = true;
    lockPersonality = true;

    # Resource limits
    memoryMax = "256M";
    tasksMax = 32;
    cpuQuota = "50%";

    # I/O limits
    serviceConfig = {
      IOWeight = 100;
      IOReadBandwidthMax = "10M";
      IOWriteBandwidthMax = "5M";
    };
  };

  launchd = {
    # macOS doesn't have equivalent sandboxing
    # Would need custom sandbox profile
    runAtLoad = true;
    keepAlive = true;

    softResourceLimits = {
      MemoryLock = 268435456; # 256 MiB
      NumberOfProcesses = 32;
    };

    # Best effort: background priority
    processType = "Background";
  };

  runit = {
    # Manual resource limits via chpst
    chpstOpts = [
      "-m 268435456"  # 256 MiB memory
      "-o 1024"       # 1024 open files
      "-p 32"         # 32 processes
    ];

    # Manual isolation would require additional tools
    preExec = ''
      echo "Warning: Limited sandboxing on runit" >&2
      echo "Consider using firejail or similar for isolation" >&2
    '';
  };
};
```

### 6. BSD rc.d Service with Jail Support

```nix
services.nginx-bsd = {
  enable = true;
  description = "Nginx HTTP server (BSD variant)";

  command = "${pkgs.nginx}/bin/nginx";
  args = [ "-g" "daemon off;" ];

  user = "nginx";
  group = "nginx";

  environment = {
    LANG = "en_US.UTF-8";
  };

  preStart = ''
    # Ensure directories exist (manual on BSD)
    mkdir -p /var/lib/nginx /var/log/nginx /var/run/nginx
    chown nginx:nginx /var/lib/nginx /var/log/nginx /var/run/nginx

    # Test configuration
    ${pkgs.nginx}/bin/nginx -t -c /etc/nginx/nginx.conf
  '';

  restart = "never"; # BSD rc.d doesn't supervise

  # BSD rc.d specific configuration
  rcd = {
    # Dependency declarations (FreeBSD/NetBSD/DragonFly only)
    provide = [ "nginx" ];
    require = [ "NETWORKING" "DAEMON" ];
    before = [ "SERVERS" ];
    keywords = [ "shutdown" ];

    # Process management
    pidfile = "/var/run/nginx.pid";
    sigStop = "QUIT";  # Graceful shutdown
    sigReload = "HUP";

    # Configuration validation
    requiredFiles = [ "/etc/nginx/nginx.conf" ];

    # Default flags (can be overridden in rc.conf)
    flags = "-c /etc/nginx/nginx.conf";

    # Additional commands
    extraCommands = [ "reload" "configtest" "upgrade" ];

    # FreeBSD-specific: Service jail support
    serviceJail = "net_basic"; # Requires basic networking in jail

    # FreeBSD-specific: Resource limits
    loginClass = "webserver"; # Defined in /etc/login.conf
    limits = "openfiles 65536";

    # FreeBSD-specific: Multiple profiles
    profiles = {
      production = {
        flags = "-c /etc/nginx/nginx-prod.conf";
        pidfile = "/var/run/nginx-prod.pid";
        requiredFiles = [ "/etc/nginx/nginx-prod.conf" ];
      };
      staging = {
        flags = "-c /etc/nginx/nginx-staging.conf";
        pidfile = "/var/run/nginx-staging.pid";
        requiredFiles = [ "/etc/nginx/nginx-staging.conf" ];
      };
    };

    # OpenBSD-specific (alternative to FreeBSD settings above)
    pexp = "nginx: master process"; # Process pattern for pgrep
    timeout = 60; # Longer timeout for stop

    # Pre/post hooks
    startPrecmd = ''
      # Additional validation
      if [ ! -d /var/lib/nginx ]; then
        echo "Error: /var/lib/nginx does not exist"
        return 1
      fi
    '';

    startPostcmd = ''
      echo "Nginx started successfully at $(date)" >> /var/log/nginx/startup.log
    '';

    stopPostcmd = ''
      echo "Nginx stopped at $(date)" >> /var/log/nginx/shutdown.log
    '';

    # Custom reload command
    reloadCmd = ''
      if [ -f $pidfile ]; then
        kill -HUP $(cat $pidfile)
      else
        echo "Nginx not running (no pidfile)"
        return 1
      fi
    '';
  };

  # Also support systemd for Linux deployments of same service
  systemd = lib.mkIf pkgs.stdenv.isLinux {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    # Security hardening on systemd
    privateTmp = true;
    protectHome = true;
    protectSystem = "strict";
    capabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
    limitNOFILE = 65536;
  };

  # Also support launchd for macOS deployments
  launchd = lib.mkIf pkgs.stdenv.isDarwin {
    runAtLoad = true;
    keepAlive = true;
    processType = "Standard";
  };
};
```

This example demonstrates:
- **Dependency management**: PROVIDE/REQUIRE/BEFORE for startup ordering
- **FreeBSD profiles**: Multiple service instances (production/staging)
- **FreeBSD jails**: Service jail compatibility with network access
- **Resource limits**: Login class and file descriptor limits
- **Signal handling**: Graceful shutdown (QUIT) and reload (HUP)
- **Pre/post hooks**: Directory setup and logging
- **OpenBSD compatibility**: Using pexp for process matching
- **Cross-platform**: Same service works on BSD, Linux (systemd), and macOS (launchd)

---

## Migration Path

### Phase 1: Parallel Adoption

Allow both old and new syntax:

```nix
# Old systemd-only syntax (still works)
systemd.services.myservice = {
  description = "My service";
  serviceConfig = {
    ExecStart = "${pkgs.myapp}/bin/myapp";
    User = "myuser";
  };
};

# New unified syntax (preferred)
services.myservice = {
  enable = true;
  description = "My service";
  command = "${pkgs.myapp}/bin/myapp";
  user = "myuser";
};
```

Both generate the same systemd unit. The new syntax is purely additive.

### Phase 2: Migration Helpers

Provide tools to convert existing definitions:

```nix
lib.services.fromSystemd = systemdConfig: {
  # Automatically convert systemd.services.* to unified format
  enable = systemdConfig.enable or true;
  description = systemdConfig.description;
  command = /* extract from ExecStart */;
  user = systemdConfig.serviceConfig.User or "root";
  # ... etc

  systemd = {
    # Preserve systemd-specific options
    wantedBy = systemdConfig.wantedBy;
    after = systemdConfig.after;
    serviceConfig = systemdConfig.serviceConfig;
  };
};

# Usage:
services.nginx = lib.services.fromSystemd config.systemd.services.nginx;
```

### Phase 3: Gradual Module Updates

Update NixOS modules one at a time to use unified interface:

```nix
# services/nginx/default.nix

{ config, lib, pkgs, ... }:

let
  cfg = config.services.nginx; # Now uses unified interface!

in {
  options.services.nginx = {
    # ... nginx-specific options ...
  };

  config = lib.mkIf cfg.enable {
    services.nginx = { # Unified service interface
      enable = true;
      description = "Nginx HTTP server";
      command = "${cfg.package}/bin/nginx";
      args = [ "-c" cfg.configFile ];
      # ... etc

      systemd = {
        wantedBy = [ "multi-user.target" ];
        # ... systemd-specific config
      };
    };

    # Additional nginx-specific setup
    environment.etc."nginx/nginx.conf".text = cfg.configuration;
  };
}
```

### Phase 4: Cross-Platform Modules

New modules that work everywhere:

```nix
# services/myapp/default.nix

{ config, lib, pkgs, ... }:

let
  cfg = config.services.myapp;

in {
  options.services.myapp = {
    # ... app-specific options ...
  };

  config = lib.mkIf cfg.enable {
    services.myapp = {
      enable = true;
      description = "My portable application";
      command = "${cfg.package}/bin/myapp";
      args = [ "--config" cfg.configFile ];
      user = "myapp";
      group = "myapp";
      stateDirectory = "myapp";

      # Works on Linux with systemd
      systemd = lib.mkIf pkgs.stdenv.isLinux {
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        privateTmp = true;
      };

      # Works on macOS with launchd
      launchd = lib.mkIf pkgs.stdenv.isDarwin {
        runAtLoad = true;
        keepAlive = true;
      };

      # Works on alternative init systems
      runit = lib.mkIf cfg.useRunit {
        checkScript = ''
          ${pkgs.curl}/bin/curl -f http://localhost:${toString cfg.port}/health
        '';
      };
    };
  };
}
```

---

## Advanced Features

### Cross-Cutting Security Policies

Similar to systemd-confinement.nix, apply policies across services:

```nix
# security/service-hardening.nix

{ config, lib, ... }:

{
  options = {
    security.hardenServices = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Apply security hardening to all services";
    };
  };

  config = lib.mkIf config.security.hardenServices {
    # Apply to all services
    services = lib.mapAttrs (name: svc: {
      systemd = {
        privateTmp = lib.mkDefault true;
        protectHome = lib.mkDefault true;
        protectSystem = lib.mkDefault "strict";
        noNewPrivileges = lib.mkDefault true;
        restrictAddressFamilies = lib.mkDefault [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        systemCallFilter = lib.mkDefault [ "@system-service" "~@privileged" ];
      };
    }) config.services;
  };
}
```

### Service Groups

Define groups of related services:

```nix
serviceGroups.web = {
  services = [ "nginx" "php-fpm" "redis" ];

  # Common configuration
  restart = "on-failure";

  systemd = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
  };

  # Operations on the group
  enable = true; # Enable all services
};

# Equivalent to:
services.nginx = { enable = true; restart = "on-failure"; ... };
services.php-fpm = { enable = true; restart = "on-failure"; ... };
services.redis = { enable = true; restart = "on-failure"; ... };
```

### Service Dependencies (Cross-Manager)

Abstract dependency specification:

```nix
services.webapp = {
  dependsOn = [ "database" "cache" ];
  # Translates to:
  # - systemd: After=database.service cache.service, Wants=...
  # - launchd: KeepAlive.OtherJobEnabled = { database = true; cache = true; }
  # - runit: sv check in preExec
};
```

### Development Environments

Same service definitions for dev environments:

```nix
# Systemd (production)
services.myapp = {
  enable = true;
  # ... production config
};

# Dev environment (direnv + runit-like supervision)
devShell = pkgs.mkShell {
  packages = [ pkgs.overmind ]; # Process supervisor

  shellHook = ''
    # Generate Procfile from service definitions
    ${lib.services.toProcfile config.services}
  '';
};
```

---

## Conclusion

This cross-service interface design provides:

1. **Portability**: Write once, deploy to systemd, launchd, runit, or BSD rc.d
2. **Power**: Full access to platform-specific features when needed
3. **Safety**: Validation and warnings for incompatible options
4. **Familiarity**: Similar to existing NixOS systemd.services API
5. **Composability**: Support for cross-cutting concerns via module system
6. **Migration**: Gradual adoption path from existing systemd-only modules
7. **BSD Support**: Full support for FreeBSD, NetBSD, DragonFly BSD, and OpenBSD via rc.d
8. **nixos-bsd Ready**: Compatible with nixos-bsd project for BSD-based NixOS variants

The two-tier approach (common core + manager-specific extensions) balances simplicity with flexibility, making it practical for real-world use while maintaining the declarative benefits that make NixOS powerful. With support for 5 service managers across Linux, macOS, and BSD platforms, this interface enables truly portable service definitions.

### Next Steps

1. Implement core module infrastructure
2. Create translation functions for each service manager
3. Build validation and warning system
4. Develop migration tooling
5. Update key services (nginx, postgresql, etc.) to use unified interface
6. Document and gather community feedback
7. Iterate based on real-world usage

### Open Questions

1. Should we support service manager autodetection, or require explicit selection?
2. How to handle user services (systemd --user vs launchd user agents)?
3. Should we provide a "minimal common denominator" mode that errors on manager-specific options?
4. How to test cross-platform service definitions in CI?
5. Integration with home-manager for user-level services?
6. Support for other init systems (OpenRC, s6, etc.)?
7. **How to handle BSD rc.d variant differences (FreeBSD vs OpenBSD vs NetBSD vs DragonFly)?**
   - Should we have variant-specific sub-options?
   - Generate appropriate rc.d script based on detected BSD variant?
   - Validate variant-specific features (service jails, profiles, pexp)?
8. **Should BSD rc.d services integrate with nixos-bsd when available?**
   - How does nixos-bsd handle service management currently?
   - Can we upstream this interface to nixos-bsd?
9. **How to handle lack of supervision in BSD rc.d?**
   - Document external supervisor options (daemontools, s6, runit)?
   - Provide helpers for integrating with process supervisors?
   - Recommend specific patterns for production deployments?
10. **BSD-specific packaging and deployment:**
    - How to handle FreeBSD ports vs packages integration?
    - Should we support automatic rc.conf generation?
    - How to handle OpenBSD's rcctl integration?
11. **Cross-BSD portability testing:**
    - How to validate services work across all BSD variants?
    - CI infrastructure for FreeBSD, OpenBSD, NetBSD, DragonFly BSD?
12. **Integration with BSD jails (FreeBSD):**
    - Should we provide higher-level jail configuration?
    - Automatic service jail setup?
    - Jail-aware dependency resolution?

---

**Document Version**: 1.1
**Date**: 2026-02-15
**Status**: Design Proposal

**Changelog**:
- v1.1 (2026-02-15): Added comprehensive BSD rc.d support for FreeBSD, NetBSD, DragonFly BSD, and OpenBSD
- v1.0 (2026-02-15): Initial design with systemd, launchd, and runit support
