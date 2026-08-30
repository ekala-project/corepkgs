# Auto-enable thermal management for Intel CPUs on bare-metal
{
  lib,
  config,
  ...
}:
let
  facterLib = import ./lib.nix lib;
  inherit (config.hardware.facter) report;
  isBaremetal = config.hardware.facter.detected.virtualisation.none.enable;
  isIntel = config.hardware.facter.detected.cpu.intel.enable;
in
{
  options.hardware.facter.detected.thermal.enable =
    lib.mkEnableOption "Facter thermal management"
    // {
      default = isIntel && isBaremetal;
      defaultText = "hardware dependent";
    };

  config =
    lib.mkIf (config.hardware.facter.enable && config.hardware.facter.detected.thermal.enable)
      {
        services.thermald.enable = lib.mkDefault true;
      };
}
