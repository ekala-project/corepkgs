# Kernel package configuration for ekaos
{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    boot.kernelPackages = mkOption {
      type = types.unspecified;
      default = pkgs.linuxPackages;
      example = literalExpression "pkgs.linuxPackages_latest";
      description = ''
        Kernel package set to use for the system.

        This determines which Linux kernel version will be used
        and provides access to kernel modules.

        Common values:
        - pkgs.linuxPackages - Default stable kernel
        - pkgs.linuxPackages_latest - Latest kernel
        - pkgs.linuxPackages_hardened - Hardened kernel
      '';
    };

    boot.kernelParams = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "quiet" "splash" ];
      description = ''
        Kernel command line parameters.

        These are passed to the kernel at boot time.
        Common parameters:
        - quiet: Reduce boot messages
        - splash: Show boot splash screen
        - nomodeset: Disable kernel mode setting
        - console=ttyS0,115200: Serial console
      '';
    };

    boot.kernelModules = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "kvm-intel" "virtio_net" ];
      description = ''
        List of kernel modules to load at boot.

        These modules will be loaded by the init system.
      '';
    };

    system.boot.loader.kernelFile = mkOption {
      type = types.str;
      internal = true;
      default = pkgs.stdenv.hostPlatform.linux-kernel.target or "bzImage";
      description = ''
        Name of the kernel file in the kernel package.
        Usually "bzImage" for x86_64, "Image" for ARM.
      '';
    };
  };

  config = {
    # Add init parameter to kernel params
    boot.kernelParams = mkBefore [
      "init=${config.system.build.toplevel}/init"
    ];
  };
}
