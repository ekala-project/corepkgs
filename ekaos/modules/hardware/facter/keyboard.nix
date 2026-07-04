# Auto-detect keyboard hardware and load kernel modules
{ lib, config, ... }:
let
  facterLib = import ./lib.nix lib;
  inherit (config.hardware.facter) report;
in
{
  options.hardware.facter.detected.keyboard.kernelModules = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = lib.unique (facterLib.collectDrivers (report.hardware.keyboard or [ ]));
    defaultText = "hardware dependent";
    description = "Kernel modules for keyboard hardware.";
  };

  config = lib.mkIf config.hardware.facter.enable {
    boot.initrd.availableKernelModules = config.hardware.facter.detected.keyboard.kernelModules;
  };
}
