# Auto-enable firmware updates on UEFI bare-metal systems
{
  lib,
  config,
  ...
}:
let
  isBaremetal = config.hardware.facter.detected.virtualisation.none.enable;
  isUefi = config.hardware.facter.detected.uefi.supported;
in
{
  options.hardware.facter.detected.fwupd.enable =
    lib.mkEnableOption "Facter firmware update support"
    // {
      default = isBaremetal && isUefi;
      defaultText = "hardware dependent";
    };

  config = lib.mkIf (config.hardware.facter.enable && config.hardware.facter.detected.fwupd.enable) {
    services.fwupd.enable = lib.mkDefault true;
  };
}
