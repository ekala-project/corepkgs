# Auto-enable Bluetooth userspace stack when hardware is detected
{
  lib,
  config,
  ...
}:
let
  inherit (config.hardware.facter) report;
  isBaremetal = config.hardware.facter.detected.virtualisation.none.enable;
in
{
  options.hardware.facter.detected.bluetooth.stack.enable =
    lib.mkEnableOption "Facter Bluetooth stack"
    // {
      default = builtins.length (report.hardware.bluetooth or [ ]) > 0 && isBaremetal;
      defaultText = "hardware dependent";
    };

  config =
    lib.mkIf (config.hardware.facter.enable && config.hardware.facter.detected.bluetooth.stack.enable)
      {
        hardware.bluetooth.enable = lib.mkDefault true;
      };
}
