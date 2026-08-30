# Auto-enable TrackPoint on ThinkPad systems
{
  lib,
  config,
  ...
}:
let
  inherit (config.hardware.facter) report;

  # Detect ThinkPad by SMBIOS system product name
  isThinkPad =
    let
      sysInfo = report.smbios.system or null;
    in
    sysInfo != null && lib.hasInfix "ThinkPad" (sysInfo.product_name or "");
in
{
  options.hardware.facter.detected.trackpoint.enable =
    lib.mkEnableOption "Facter TrackPoint detection"
    // {
      default = isThinkPad;
      defaultText = "hardware dependent";
    };

  config =
    lib.mkIf (config.hardware.facter.enable && config.hardware.facter.detected.trackpoint.enable)
      {
        hardware.trackpoint.enable = lib.mkDefault true;
        hardware.trackpoint.emulateWheel = lib.mkDefault true;
      };
}
