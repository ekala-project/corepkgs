# Periodic SSD TRIM service
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.fstrim;

in

{
  options.services.fstrim = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable periodic SSD TRIM of mounted partitions.";
    };

    interval = mkOption {
      type = types.str;
      default = "weekly";
      description = ''
        How often to run fstrim. For most systems a weekly trim is sufficient.
        Uses systemd calendar event syntax (e.g. "weekly", "daily", "monthly").
      '';
    };
  };

  config = mkIf cfg.enable {
    timers.fstrim = {
      enable = true;
      description = "Discard unused filesystem blocks (TRIM)";
      script = ''
        ${pkgs.util-linux}/bin/fstrim --listed-in /etc/fstab:/proc/self/mountinfo --verbose --quiet-unsupported
      '';
      schedule.calendar = cfg.interval;
      systemd = {
        wantedBy = [ "timers.target" ];
      };
    };
  };
}
