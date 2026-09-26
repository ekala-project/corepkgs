# Adios port of ekaos/modules/hardware/cpu.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{
  types,
  lib,
  pkgs,
  ...
}:

{
  options = {
    amdUpdateMicrocode = {
      type = types.bool;
      default = false;
      description = ''
        Whether to update AMD CPU microcode at boot.

        Loads the latest AMD microcode via the initramfs early-load mechanism.
      '';
    };

    intelUpdateMicrocode = {
      type = types.bool;
      default = false;
      description = ''
        Whether to update Intel CPU microcode at boot.

        Loads the latest Intel microcode via the initramfs early-load mechanism.
      '';
    };
  };

  impl =
    { options, ... }:
    lib.merge.attrs.recursively {
      mutators = [
        (
          if options.amdUpdateMicrocode then
            {
              hardware.firmware = [ pkgs.amd-microcode ];
              boot.initrd.kernelModules = [ "microcode" ];
            }
          else
            { }
        )

        (
          if options.intelUpdateMicrocode then
            {
              hardware.firmware = [ pkgs.intel-microcode ];
              boot.initrd.kernelModules = [ "microcode" ];
            }
          else
            { }
        )
      ];
    };
}
