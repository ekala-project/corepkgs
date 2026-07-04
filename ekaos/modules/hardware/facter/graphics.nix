# Auto-detect graphics hardware and load appropriate kernel modules
{ lib, config, ... }:
let
  facterLib = import ./lib.nix lib;
  cfg = config.hardware.facter.detected.graphics;
in
{
  options.hardware.facter.detected = {
    graphics.enable = lib.mkEnableOption "Facter graphics" // {
      default = builtins.length (config.hardware.facter.report.hardware.monitor or [ ]) > 0;
      defaultText = "hardware dependent";
    };

    boot.graphics.kernelModules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      # Exclude nouveau to avoid conflicts with proprietary nvidia drivers
      default = lib.remove "nouveau" (
        facterLib.stringSet (
          facterLib.collectDrivers (config.hardware.facter.report.hardware.graphics_card or [ ])
        )
      );
      defaultText = "hardware dependent";
      description = "Kernel modules for graphics hardware.";
    };
  };

  config = lib.mkIf (config.hardware.facter.enable && cfg.enable) {
    boot.initrd.kernelModules = config.hardware.facter.detected.boot.graphics.kernelModules;
  };
}
