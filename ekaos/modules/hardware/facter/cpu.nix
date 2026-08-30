# Auto-configure CPU microcode and frequency scaling
{
  lib,
  config,
  ...
}:
let
  facterLib = import ./lib.nix lib;
  inherit (config.hardware.facter) report;
  cfg = config.hardware.facter.detected.cpu;
  isBaremetal = config.hardware.facter.detected.virtualisation.none.enable;
in
{
  options.hardware.facter.detected.cpu = {
    amd.enable = lib.mkEnableOption "Facter AMD CPU detection" // {
      default = facterLib.hasAmdCpu report;
      defaultText = "hardware dependent";
    };

    intel.enable = lib.mkEnableOption "Facter Intel CPU detection" // {
      default = facterLib.hasIntelCpu report;
      defaultText = "hardware dependent";
    };
  };

  config = lib.mkIf config.hardware.facter.enable (
    lib.mkMerge [
      # AMD microcode updates
      (lib.mkIf (cfg.amd.enable && isBaremetal) {
        hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
        # amd-pstate active mode for modern frequency scaling (kernel 6.3+)
        boot.kernelParams = [ "amd_pstate=active" ];
      })

      # Intel microcode updates
      (lib.mkIf (cfg.intel.enable && isBaremetal) {
        hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      })
    ]
  );
}
