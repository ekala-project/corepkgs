# Adios port of ekaos/modules/hardware/facter/gpu.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, lib, ... }:

{
  options = {
    amdEnable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        let
          facterLib = import ./lib.nix { };
        in
        facterLib.hasAmdGpu inputs.facter.report;
      description = "Whether to enable Facter AMD GPU detection.";
    };

    intelEnable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        let
          facterLib = import ./lib.nix { };
        in
        facterLib.hasIntelGpu inputs.facter.report;
      description = "Whether to enable Facter Intel GPU detection.";
    };

    nvidiaEnable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        let
          facterLib = import ./lib.nix { };
        in
        facterLib.hasNvidiaGpu inputs.facter.report;
      description = "Whether to enable Facter NVIDIA GPU detection.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
  };

  impl =
    { options, inputs }:
    lib.merge.attrs.recursively {
      mutators = [
        # AMD GPU: enable graphics with 32-bit support, early KMS for display at boot
        # TODO(adios-cutover): legacy mkDefault priority lost (both options).
        (
          if options.amdEnable then
            {
              hardware.graphics.enable = true;
              hardware.graphics.enable32Bit = true;
              boot.initrd.kernelModules = [ "amdgpu" ];
            }
          else
            { }
        )

        # Intel GPU: enable graphics stack, load i915 early for display at boot
        # TODO(adios-cutover): legacy mkDefault priority lost.
        (
          if options.intelEnable then
            {
              hardware.graphics.enable = true;
              boot.initrd.kernelModules = [ "i915" ];
            }
          else
            { }
        )

        # NVIDIA GPU: enable graphics stack
        # Driver configuration is handled by hardware.nvidia (via facter/nvidia.nix)
        # TODO(adios-cutover): legacy mkDefault priority lost.
        (
          if options.nvidiaEnable then
            {
              hardware.graphics.enable = true;
            }
          else
            { }
        )
      ];
    };
}
