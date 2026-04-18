# Launchd-specific service options for macOS
# See: man launchd.plist(5)

{ lib }:

with lib;

{
  launchdOptions = { name, config, ... }: {
    options = {
      # Launch behavior
      runAtLoad = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Start the service immediately when loaded (at boot or login).
          Maps to the RunAtLoad key in launchd.plist.
        '';
      };

      keepAlive = mkOption {
        type = types.either types.bool (types.submodule {
          options = {
            successfulExit = mkOption {
              type = types.nullOr types.bool;
              default = null;
              description = ''
                Restart behavior based on exit status:
                - false: Restart only on failure (non-zero exit)
                - true: Restart only on success (zero exit)
              '';
            };

            networkState = mkOption {
              type = types.nullOr types.bool;
              default = null;
              description = ''
                Start when network is available.
                - true: Start when network becomes available
              '';
            };

            pathState = mkOption {
              type = types.nullOr (types.attrsOf types.bool);
              default = null;
              example = { "/etc/myconfig" = true; };
              description = ''
                Start when paths exist or don't exist.
                - path = true: Start when path exists
                - path = false: Start when path doesn't exist
              '';
            };

            otherJobEnabled = mkOption {
              type = types.nullOr (types.attrsOf types.bool);
              default = null;
              example = { "com.example.other" = true; };
              description = ''
                Start based on other job states.
                - label = true: Start when other job is enabled
                - label = false: Start when other job is disabled
              '';
            };
          };
        });
        default = false;
        example = literalExpression ''{ successfulExit = false; }'';
        description = ''
          Restart behavior for the service.

          - true: Always restart
          - false: Never restart (one-shot)
          - { successfulExit = false; }: Restart only on failure
          - { networkState = true; }: Start when network available

          This is launchd's equivalent to systemd's Restart= option.
        '';
      };

      # Event-driven launch triggers
      watchPaths = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [ "/etc/myservice/config.yaml" "/var/lib/myservice/data" ];
        description = ''
          Start the service when any of these paths are modified.
          Uses FSEvents for efficient monitoring.

          Useful for configuration reload services or file processing.

          Note: Can include shell variables like $HOME which will be
          expanded at runtime by launchd.
        '';
      };

      queueDirectories = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [ "/var/spool/myservice" ];
        description = ''
          Start the service when files appear in these directories.
          Useful for batch processing and queue workers.

          launchd monitors these directories and launches the service
          when new files are created.

          Note: Can include shell variables like $HOME which will be
          expanded at runtime by launchd.
        '';
      };

      # Scheduling
      startInterval = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 3600;
        description = ''
          Start the service at this interval (in seconds).
          Similar to systemd's OnActiveSec timer.

          The service will be started repeatedly at the specified interval,
          regardless of how long it runs.
        '';
      };

      startCalendarInterval = mkOption {
        type = types.nullOr (types.either
          (types.submodule {
            options = {
              minute = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Minute (0-59)";
              };
              hour = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Hour (0-23)";
              };
              day = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Day of month (1-31)";
              };
              weekday = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Day of week (0=Sunday, 6=Saturday)";
              };
              month = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Month (1-12)";
              };
            };
          })
          (types.listOf (types.submodule {
            options = {
              minute = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Minute (0-59)";
              };
              hour = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Hour (0-23)";
              };
              day = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Day of month (1-31)";
              };
              weekday = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Day of week (0=Sunday, 6=Saturday)";
              };
              month = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "Month (1-12)";
              };
            };
          }))
        );
        default = null;
        example = literalExpression ''{ hour = 2; minute = 30; }'';
        description = ''
          Start the service at specific calendar times.
          Can be a single time or list of times.

          Examples:
          - { hour = 2; minute = 30; } - Run at 2:30 AM daily
          - { weekday = 0; hour = 3; } - Run at 3:00 AM every Sunday
          - [{ hour = 9; } { hour = 17; }] - Run at 9 AM and 5 PM daily

          Note: All times are in local timezone.
        '';
      };

      # Process management
      processType = mkOption {
        type = types.enum [ "Standard" "Background" "Interactive" "Adaptive" ];
        default = "Standard";
        description = ''
          macOS process classification for scheduling priority.

          - Standard: Normal priority (default)
          - Background: Low priority, throttled when system is busy
          - Interactive: High priority for UI responsiveness
          - Adaptive: Dynamically adjusted based on user interaction

          This affects how macOS schedules CPU time for the process.
        '';
      };

      nice = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 10;
        description = ''
          Process nice value (-20 to 20).
          Lower values = higher priority, higher values = lower priority.

          Note: Negative values typically require root privileges.
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
          Soft resource limits (setrlimit-style).

          Valid keys:
          - Core: Max core dump size (bytes)
          - CPU: Max CPU time (seconds)
          - Data: Max data segment size (bytes)
          - FileSize: Max file size (bytes)
          - MemoryLock: Max locked memory (bytes)
          - NumberOfFiles: Max open file descriptors
          - NumberOfProcesses: Max number of processes
          - ResidentSetSize: Max resident set size (bytes)
          - Stack: Max stack size (bytes)

          Soft limits can be increased up to hard limits by the process.
        '';
      };

      hardResourceLimits = mkOption {
        type = types.attrsOf types.int;
        default = {};
        description = ''
          Hard resource limits (setrlimit-style).
          Same keys as softResourceLimits.

          Hard limits cannot be exceeded, even by the process itself.
          Only root can raise hard limits.
        '';
      };

      # I/O settings
      standardInPath = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/dev/null";
        description = ''
          Path to use for standard input.
          If not specified, launchd uses /dev/null for stdin.

          Note: Can include shell variables which will be expanded at runtime.
        '';
      };

      # Timeout
      exitTimeout = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 30;
        description = ''
          Seconds to wait for clean exit before sending SIGKILL.
          Default is 20 seconds if not specified.

          When stopping the service, launchd first sends SIGTERM,
          waits this many seconds, then sends SIGKILL if still running.
        '';
      };

      # Security
      umask = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 18;  # 022 octal = 18 decimal
        description = ''
          File creation mask (in decimal, not octal).

          Note: This must be specified in DECIMAL.
          Common values:
          - 18 (022 octal): User can write, others read-only
          - 63 (077 octal): User-only access
        '';
      };

      sessionCreate = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Create a new security session (audit session).
          Typically used for user-facing GUI applications.

          System daemons should not use this option.
        '';
      };

      # Additional launchd features
      enableTransactions = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable XPC transaction support.
          Prevents service exit while XPC transactions are active.

          Useful for services that handle XPC requests and need to
          complete them before exiting.
        '';
      };

      abandonProcessGroup = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Don't kill the entire process group when service stops.
          Allows child processes to outlive the parent.

          By default, launchd kills all processes in the group.
        '';
      };

      # Label (identifier)
      label = mkOption {
        type = types.str;
        default = "org.nixos.${name}";
        example = "com.example.myservice";
        description = ''
          Unique identifier for the service (reverse DNS notation).
          This is the Label key in the plist.

          Default: org.nixos.<servicename>

          This label is used to identify the service to launchctl.
        '';
      };

      # Raw plist passthrough for advanced options
      extraConfig = mkOption {
        type = types.attrs;
        default = {};
        example = literalExpression ''
          {
            LegacyTimers = true;
            ThrottleInterval = 10;
            EnablePressuredExit = true;
          }
        '';
        description = ''
          Additional launchd.plist keys not covered by typed options above.

          Use this for advanced or macOS version-specific features.
          See launchd.plist(5) for all available keys.

          These options are merged into the final plist, allowing you
          to access any launchd feature not explicitly supported.
        '';
      };
    };
  };
}
