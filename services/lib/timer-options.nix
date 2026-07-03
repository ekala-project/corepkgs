# Common timer/scheduled task options shared across all service managers
{ lib }:

let
  inherit (lib)
    types
    mkOption
    mkEnableOption
    literalExpression
    ;
  # Schedule submodule — platform-independent scheduling
  scheduleOptions = {
    options = {
      calendar = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "daily";
        description = ''
          Calendar expression for when to trigger.
          Supported values: "minutely", "hourly", "daily", "weekly", "monthly",
          or systemd OnCalendar syntax like "*-*-* 02:30:00", "Mon..Fri 09:00".
          Non-systemd platforms translate to equivalent cron expressions.
        '';
      };

      interval = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 3600;
        description = ''
          Interval in seconds between runs.
          Alternative to calendar — use one or the other.
        '';
      };

      onBoot = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "5min";
        description = ''
          Time after boot to first trigger.
          Systemd: OnBootSec. Other platforms: sleep in startup script.
        '';
      };

      persistent = mkOption {
        type = types.bool;
        default = false;
        description = ''
          If true, catch up on missed runs when the system was off.
          Only supported on systemd. Ignored on other platforms.
        '';
      };

      randomDelay = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 300;
        description = ''
          Random delay in seconds added to prevent thundering herd.
          Systemd: RandomizedDelaySec. Other platforms: sleep $RANDOM.
        '';
      };
    };
  };

in
{
  inherit scheduleOptions;

  # Common timer options that work across all platforms
  commonTimerOptions = {
    enable = mkEnableOption "this scheduled task";

    description = mkOption {
      type = types.str;
      example = "Nix garbage collection";
      description = "Human-readable description of the scheduled task.";
    };

    script = mkOption {
      type = types.lines;
      example = ''
        echo "Running cleanup"
        find /tmp -type f -mtime +7 -delete
      '';
      description = "Shell script to run when the timer fires.";
    };

    user = mkOption {
      type = types.str;
      default = "root";
      example = "nobody";
      description = "User to run the script as.";
    };

    group = mkOption {
      type = types.str;
      default = "root";
      description = "Group to run the script as.";
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Environment variables for the script.";
    };

    path = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Packages to add to PATH when running the script.";
    };

    schedule = mkOption {
      type = types.submodule scheduleOptions;
      description = "When to run the scheduled task.";
    };
  };
}
