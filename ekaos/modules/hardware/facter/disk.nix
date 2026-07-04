# Auto-detect disk controller kernel modules
{ lib, config, ... }:
let
  facterLib = import ./lib.nix lib;
  inherit (config.hardware.facter) report;
in
{
  options.hardware.facter.detected.boot.disk.kernelModules = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = lib.unique (
      facterLib.collectDrivers (
        (report.hardware.firewire_controller or [ ])
        ++ (report.hardware.disk or [ ])
        ++ (report.hardware.storage_controller or [ ])
      )
    );
    defaultText = "hardware dependent";
    description = "Kernel modules needed to access disks.";
  };

  config = lib.mkIf config.hardware.facter.enable {
    boot.initrd.availableKernelModules = config.hardware.facter.detected.boot.disk.kernelModules;
  };
}
