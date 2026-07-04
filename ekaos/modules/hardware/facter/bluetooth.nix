# Auto-detect Bluetooth hardware and load kernel modules
{ lib, config, ... }:
let
  facterLib = import ./lib.nix lib;
  inherit (config.hardware.facter) report;
in
{
  options.hardware.facter.detected.bluetooth.kernelModules = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = lib.unique (facterLib.collectDrivers (report.hardware.bluetooth or [ ]));
    defaultText = "hardware dependent";
    description = "Kernel modules for Bluetooth hardware.";
  };

  config = lib.mkIf config.hardware.facter.enable {
    boot.initrd.availableKernelModules = config.hardware.facter.detected.bluetooth.kernelModules;
  };
}
