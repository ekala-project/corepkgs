# BSD rc.d-specific service options
# See: rc.d(8), rc.subr(8) on various BSD systems

{ lib }:

with lib;

{
  rcdOptions = { name, config, ... }: {
    options = {
      # Target BSD variant
      variant = mkOption {
        type = types.enum [ "freebsd" "openbsd" "netbsd" "dragonfly" ];
        default = "freebsd";
        description = ''
          Target BSD variant for rc.d script generation.

          - freebsd: Full-featured with rcorder (most common)
          - openbsd: Simplified sequential system
          - netbsd: Similar to FreeBSD
          - dragonfly: Based on NetBSD, similar to FreeBSD

          The variant affects variable names, dependency handling,
          and available features.
        '';
      };

      # rcorder dependencies (FreeBSD/NetBSD/DragonFly)
      rcProvide = mkOption {
        type = types.listOf types.str;
        default = [ name ];
        example = [ "myservice" "oldname" ];
        description = ''
          Services provided by this script (PROVIDE keyword).

          Used by rcorder to determine what this script offers.
          Defaults to the service name.

          Note: Ignored on OpenBSD (no rcorder).
        '';
      };

      rcRequire = mkOption {
        type = types.listOf types.str;
        default = [ "DAEMON" ];
        example = [ "DAEMON" "NETWORKING" "ldconfig" ];
        description = ''
          Services that must start before this one (REQUIRE keyword).

          Common values:
          - DAEMON: Basic daemon environment
          - LOGIN: User logins enabled
          - NETWORKING: Network interfaces configured
          - SERVERS: Network servers started

          Note: Ignored on OpenBSD (no rcorder).
        '';
      };

      rcBefore = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "LOGIN" "securelevel" ];
        description = ''
          Services that should start after this one (BEFORE keyword).

          Less common than REQUIRE. Useful for services that other
          services depend on.

          Note: Ignored on OpenBSD (no rcorder).
        '';
      };

      rcKeywords = mkOption {
        type = types.listOf types.str;
        default = [ "shutdown" ];
        example = [ "shutdown" "nojail" ];
        description = ''
          Special rcorder keywords (KEYWORD directive).

          Common keywords:
          - shutdown: Include during system shutdown
          - nojail: Don't run in jails/zones
          - nostart: Never auto-start at boot

          Note: Ignored on OpenBSD (no rcorder).
        '';
      };

      # PID file configuration
      pidfile = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/var/run/myservice.pid";
        description = ''
          Location of the PID file for process tracking.

          If not specified, defaults to /var/run/<name>.pid on
          FreeBSD/NetBSD/DragonFly.

          On OpenBSD, can use pexp (process name pattern) instead.
        '';
      };

      # Additional rc.conf entries
      extraRcConf = mkOption {
        type = types.lines;
        default = "";
        example = literalExpression ''
          '''
          # Additional flags
          myservice_flags="-v"

          # Custom environment
          myservice_env="VAR1=value1 VAR2=value2"
          '''
        '';
        description = ''
          Additional rc.conf entries to include in sample configuration.

          These are written to a sample rc.conf.d file for user reference.
          Not automatically applied - user must add to /etc/rc.conf.
        '';
      };

      # Custom shell code in rc.d script
      extraRcScript = mkOption {
        type = types.lines;
        default = "";
        example = literalExpression ''
          '''
          # Custom stop command
          stop_cmd="''${name}_stop"
          myservice_stop() {
              echo "Gracefully stopping..."
              kill -TERM $(cat $pidfile)
          }
          '''
        '';
        description = ''
          Additional shell script code to include in the rc.d script.

          Inserted before load_rc_config/rc_cmd call.
          Useful for custom commands, additional variables, or hooks.
        '';
      };

      # Process name pattern (useful for OpenBSD)
      processName = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "python3.*myservice";
        description = ''
          Process name pattern for matching (procname/pexp).

          FreeBSD/NetBSD: Sets procname variable
          OpenBSD: Sets pexp variable

          Useful when the command is a script wrapper and you need
          to match the actual process name.
        '';
      };

      # Raw passthrough for advanced configurations
      extraConfig = mkOption {
        type = types.attrs;
        default = { };
        example = literalExpression ''
          {
            sig_reload = "USR1";
            required_files = "/etc/myservice.conf";
            required_dirs = "/var/db/myservice";
          }
        '';
        description = ''
          Additional rc.d-specific configuration not covered by typed options.

          Supported keys (FreeBSD/NetBSD/DragonFly):
          - sig_reload: Signal to send for reload (default: HUP)
          - sig_stop: Signal to send for stop (default: TERM)
          - required_files: Files that must exist
          - required_dirs: Directories that must exist
          - command_interpreter: Interpreter for command

          Use this for advanced rc.d features.
        '';
      };
    };
  };
}
