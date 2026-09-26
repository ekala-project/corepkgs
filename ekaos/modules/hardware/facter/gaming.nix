# Adios port of ekaos/modules/hardware/facter/gaming.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, ... }:

{
  options = {
    enable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        builtins.length (inputs.facter.report.hardware.joystick or [ ]) > 0 && inputs.virt.noneEnable;
      description = "Whether to enable Facter gaming peripheral detection.";
    };

    kernelModules = {
      type = types.listOf types.string;
      defaultFunc =
        { inputs, ... }:
        let
          facterLib = import ./lib.nix { };
        in
        facterLib.unique (facterLib.collectDrivers (inputs.facter.report.hardware.joystick or [ ]));
      description = "Kernel modules for detected gaming peripherals.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
    virt.from = { root }: root.hardware.facter.virtualisation;
  };

  impl =
    { options, inputs }:
    if (inputs.facter.enable && options.enable) then
      {
        # Load detected gamepad/joystick driver modules
        boot.kernelModules = options.kernelModules;

        # Common gamepad kernel modules that may not be in the facter report
        # but are needed for hot-plugged controllers
        boot.initrd.availableKernelModules = [
          "xpad" # Xbox controllers
          "hid-sony" # PlayStation controllers
          "hid-nintendo" # Nintendo controllers
        ];

        # TODO(corepkgs): Port steam-hardware udev rules for controller support
      }
    else
      { };
}
