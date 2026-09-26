# Adios port of ekaos/modules/hardware/facter/power.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, lib, ... }:

{
  options = {
    batteryEnable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        builtins.length (inputs.facter.report.hardware.battery or [ ]) > 0 || inputs.laptop.enable;
      description = "Whether to enable Facter battery detection.";
    };

    hibernateEnable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        builtins.length (inputs.facter.report.hardware.battery or [ ]) > 0
        && builtins.length (inputs.facter.report.swap or [ ]) > 0
        && inputs.virt.noneEnable;
      description = "Whether to enable Facter hibernate readiness.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
    virt.from = { root }: root.hardware.facter.virtualisation;
    laptop.from = { root }: root.hardware.facter.laptop;
  };

  impl =
    { options, inputs }:
    lib.merge.attrs.recursively {
      mutators = [
        # Battery detected: optimize for power saving
        (
          if (options.batteryEnable && inputs.virt.noneEnable) then
            {
              # SCSI link power management for battery life
              # TODO(adios-cutover): legacy mkDefault priority lost (both options).
              power.scsiLinkPolicy = "med_power_with_dipm";

              # Enable power-profiles-daemon for D-Bus power profile switching
              # (used by Quickshell power profile switcher)
              services.power-profiles-daemon.enable = true;
            }
          else
            { }
        )
      ];
    };
}
