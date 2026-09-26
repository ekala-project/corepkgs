# Adios port of ekaos/modules/services/fstrim.nix.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = true;
      description = "Whether to enable periodic SSD TRIM of mounted partitions.";
    };

    interval = {
      type = types.string;
      default = "weekly";
      description = ''
        How often to run fstrim. For most systems a weekly trim is sufficient.
        Uses systemd calendar event syntax (e.g. "weekly", "daily", "monthly").
      '';
    };
  };

  impl =
    { options, ... }:
    if !options.enable then
      { }
    else
      {
        timers.fstrim = {
          enable = true;
          description = "Discard unused filesystem blocks (TRIM)";
          script = ''
            ${pkgs.util-linux}/bin/fstrim --listed-in /etc/fstab:/proc/self/mountinfo --verbose --quiet-unsupported
          '';
          schedule.calendar = options.interval;
          systemd = {
            wantedBy = [ "timers.target" ];
          };
        };
      };
}
