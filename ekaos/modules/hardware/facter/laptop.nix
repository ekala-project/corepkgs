# Auto-configure power management for portable devices
{
  lib,
  config,
  ...
}:
let
  facterLib = import ./lib.nix lib;
  inherit (config.hardware.facter) report;
in
{
  options.hardware.facter.detected.laptop.enable =
    lib.mkEnableOption "Facter portable device detection"
    // {
      default = facterLib.isPortableChassis report;
      defaultText = "hardware dependent";
    };

  config = lib.mkIf (config.hardware.facter.enable && config.hardware.facter.detected.laptop.enable) {
    # On modern Intel HWP and AMD pstate, "powersave" still allows full
    # boost clocks — it just favors lower power states during idle
    power.cpuFreqGovernor = lib.mkDefault "powersave";

    # Auto-tune all power-saving knobs
    power.powertop.enable = lib.mkDefault true;
  };
}
