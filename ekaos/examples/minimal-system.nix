# Minimal bootable ekaos system configuration
# This is the simplest possible configuration that should boot
{ config, lib, pkgs, ... }:

{
  # System identification
  system.ekaos.version = "24.11";
  system.ekaos.label = "ekaos-minimal";

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # Use default kernel
  boot.kernelPackages = pkgs.linuxPackages;

  # Kernel parameters
  boot.kernelParams = [
    "console=ttyS0,115200"  # Serial console for VM testing
    "console=tty1"           # VGA console
  ];

  # Essential system packages
  environment.systemPackages = with pkgs; [
    coreutils
    util-linux
    systemd
  ];

  # No custom services for minimal system
  # systemd.services = {};
}
