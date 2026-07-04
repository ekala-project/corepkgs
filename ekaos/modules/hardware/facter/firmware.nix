# Auto-configure firmware for bare-metal systems
{ lib, config, ... }:
let
  facterLib = import ./lib.nix lib;
  inherit (config.hardware.facter) report;
  isBaremetal = config.hardware.facter.detected.virtualisation.none.enable;
in
{
  config = lib.mkIf (config.hardware.facter.enable && isBaremetal) {
    hardware.enableRedistributableFirmware = lib.mkDefault true;
  };
}
