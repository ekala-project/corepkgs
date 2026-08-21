# CPU microcode update support
# Provides options for AMD and Intel microcode loading
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfgAmd = config.hardware.cpu.amd;
  cfgIntel = config.hardware.cpu.intel;

in

{
  options = {
    hardware.cpu.amd.updateMicrocode = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to update AMD CPU microcode at boot.

        Loads the latest AMD microcode via the initramfs early-load mechanism.
      '';
    };

    hardware.cpu.intel.updateMicrocode = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to update Intel CPU microcode at boot.

        Loads the latest Intel microcode via the initramfs early-load mechanism.
      '';
    };
  };

  config = mkMerge [
    (mkIf cfgAmd.updateMicrocode {
      # TODO: requires amd-microcode package in core-pkgs
      hardware.firmware = [ (pkgs.amd-microcode or (throw "amd-microcode package not available")) ];
      boot.initrd.kernelModules = [ "microcode" ];
    })

    (mkIf cfgIntel.updateMicrocode {
      # TODO: requires intel-microcode package in core-pkgs
      hardware.firmware = [
        (pkgs.intel-microcode or (throw "intel-microcode package not available"))
      ];
      boot.initrd.kernelModules = [ "microcode" ];
    })
  ];
}
