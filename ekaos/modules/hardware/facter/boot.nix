# Auto-configure boot loader based on UEFI detection
{ config, lib, ... }:
{
  options.hardware.facter.detected.uefi.supported = lib.mkEnableOption "Facter UEFI detection" // {
    default = config.hardware.facter.report.uefi.supported or false;
    defaultText = "hardware dependent";
  };

  config =
    lib.mkIf (config.hardware.facter.enable && config.hardware.facter.detected.uefi.supported)
      {
        boot.loader.systemd-boot.enable = lib.mkDefault true;
        boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
      };
}
