# Adios port of ekaos/modules/hardware/facter/graphics.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, ... }:

{
  options = {
    enable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        builtins.length (inputs.facter.report.hardware.monitor or [ ]) > 0;
      description = "Whether to enable Facter graphics.";
    };

    kernelModules = {
      type = types.listOf types.string;
      defaultFunc =
        { inputs, ... }:
        let
          facterLib = import ./lib.nix { };
          drivers = facterLib.stringSet (
            facterLib.collectDrivers (inputs.facter.report.hardware.graphics_card or [ ])
          );
        in
        # Exclude nouveau to avoid conflicts with proprietary nvidia drivers
        builtins.filter (x: x != "nouveau") drivers;
      description = "Kernel modules for graphics hardware.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
  };

  impl =
    { options, inputs }:
    if (inputs.facter.enable && options.enable) then
      {
        boot.initrd.kernelModules = options.kernelModules;
        # Fallback: enable graphics when monitors are detected,
        # even if the GPU vendor is not AMD/Intel/NVIDIA
        # TODO(adios-cutover): legacy mkDefault priority lost.
        hardware.graphics.enable = true;
      }
    else
      { };
}
