# Kernel package configuration for ekaos
{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    boot.kernelPackages = mkOption {
      type = types.unspecified;
      defaultText = "pkgs.linuxPackages (linux_6_12)";
      example = literalExpression "pkgs.linuxPackages_latest";
      description = ''
        Kernel package set to use for the system.

        This determines which Linux kernel version will be used
        and provides access to kernel modules.

        Available kernel packages:
        - pkgs.linuxPackages - Default stable kernel (6.12)
        - pkgs.linuxPackages_latest - Latest kernel (6.18)
        - pkgs.linuxPackages_6_12 - Specific version 6.12
        - pkgs.linuxPackages_6_18 - Specific version 6.18
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
    # Note: init parameter is added in toplevel.nix to avoid circular dependency
  };
}
