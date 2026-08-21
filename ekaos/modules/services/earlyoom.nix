# Earlyoom — early OOM daemon
# Kills processes when memory runs low to prevent system lockups
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.earlyoom;

in

{
  options = {
    services.earlyoom = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable earlyoom, the early OOM daemon.

          earlyoom monitors memory and swap usage and kills the largest
          process when thresholds are exceeded, preventing the system
          from becoming unresponsive due to OOM conditions.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.earlyoom or (throw "earlyoom package not available in core-pkgs");
        defaultText = literalExpression "pkgs.earlyoom";
        description = "The earlyoom package to use.";
      };

      description = mkOption {
        type = types.str;
        default = "Early OOM Daemon";
        description = "Service description.";
      };

      command = mkOption {
        type = types.str;
        internal = true;
        description = "Command to run (set automatically).";
      };

      args = mkOption {
        type = types.listOf types.str;
        internal = true;
        default = [ ];
        description = "Command arguments (set automatically).";
      };

      user = mkOption {
        type = types.str;
        default = "root";
        description = "User to run service as.";
      };

      restartPolicy = mkOption {
        type = types.str;
        default = "always";
        description = "Restart policy.";
      };

      systemd = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Systemd-specific options.";
      };

      freeMemThreshold = mkOption {
        type = types.int;
        default = 10;
        example = 5;
        description = ''
          Minimum percentage of free memory before earlyoom starts killing.
        '';
      };

      freeSwapThreshold = mkOption {
        type = types.int;
        default = 10;
        example = 5;
        description = ''
          Minimum percentage of free swap before earlyoom starts killing.
        '';
      };

      freeMemKillThreshold = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 5;
        description = ''
          Send SIGKILL when free memory drops below this percentage.
          Defaults to half of freeMemThreshold.
        '';
      };

      freeSwapKillThreshold = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 5;
        description = ''
          Send SIGKILL when free swap drops below this percentage.
          Defaults to half of freeSwapThreshold.
        '';
      };

      enableNotifications = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to send D-Bus notifications on kills.";
      };

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "--prefer"
          "(^|/)(java|chrome)$"
        ];
        description = "Additional arguments passed to earlyoom.";
      };
    };
  };

  config = mkIf cfg.enable {
    services.earlyoom = {
      command = "${cfg.package}/bin/earlyoom";
      args = [
        "-m"
        (toString cfg.freeMemThreshold)
        "-s"
        (toString cfg.freeSwapThreshold)
      ]
      ++ optionals (cfg.freeMemKillThreshold != null) [
        "-M"
        (toString cfg.freeMemKillThreshold)
      ]
      ++ optionals (cfg.freeSwapKillThreshold != null) [
        "-S"
        (toString cfg.freeSwapKillThreshold)
      ]
      ++ optional cfg.enableNotifications "-n"
      ++ cfg.extraArgs;
      user = "root";
      restartPolicy = "always";
      systemd = {
        after = [ "multi-user.target" ];
        wantedBy = [ "multi-user.target" ];
      };
    };
  };
}
