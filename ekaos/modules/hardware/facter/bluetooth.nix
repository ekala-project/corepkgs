# Adios port of ekaos/modules/hardware/facter/bluetooth.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, ... }:

{
  options = {
    kernelModules = {
      type = types.listOf types.string;
      defaultFunc =
        { inputs, ... }:
        let
          facterLib = import ./lib.nix { };
        in
        facterLib.unique (facterLib.collectDrivers (inputs.facter.report.hardware.bluetooth or [ ]));
      description = "Kernel modules for Bluetooth hardware.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
  };

  impl =
    { options, inputs }:
    if inputs.facter.enable then
      {
        boot.initrd.availableKernelModules = options.kernelModules;
      }
    else
      { };
}
