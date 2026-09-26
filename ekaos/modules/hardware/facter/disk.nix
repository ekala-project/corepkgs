# Adios port of ekaos/modules/hardware/facter/disk.nix.
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
          report = inputs.facter.report;
        in
        facterLib.unique (
          facterLib.collectDrivers (
            (report.hardware.firewire_controller or [ ])
            ++ (report.hardware.disk or [ ])
            ++ (report.hardware.storage_controller or [ ])
          )
        );
      description = "Kernel modules needed to access disks.";
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
