# Kernel package configuration for ekaos
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    boot.kernelPackages = mkOption {
      type = types.unspecified;
      default = pkgs.linux.pkgs;
      defaultText = "pkgs.linux.pkgs (linux 6.12)";
      example = literalExpression "pkgs.linux.v6_18.pkgs";
      description = ''
        Kernel package set to use for the system.

        This determines which Linux kernel version will be used
        and provides access to kernel modules.

        Available kernel packages:
        - pkgs.linux.pkgs - Default stable kernel (6.12) modules
        - pkgs.linux.v6_18.pkgs - Specific version 6.18 modules
        - pkgs.linux.v6_12.pkgs - Specific version 6.12 modules

        Legacy aliases (pkgs.linuxPackages, pkgs.linuxPackages_6_18, etc.)
        are still available for backward compatibility.
      '';
    };

    boot.kernelParams = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "quiet"
        "splash"
      ];
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
      default = [ ];
      example = [
        "kvm-intel"
        "virtio_net"
      ];
      description = ''
        List of kernel modules to load at boot.

        These modules will be loaded by the init system.
      '';
    };

    boot.extraModulePackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = literalExpression "[ config.boot.kernelPackages.nvidia_x11 ]";
      description = ''
        Additional kernel module packages to include.

        These are merged into the kernel module search path alongside
        the modules from the selected kernel.
      '';
    };

    boot.consoleLogLevel = mkOption {
      type = types.int;
      default = 4;
      example = 7;
      description = ''
        The kernel console log level.

        All kernel messages with a log level smaller than this
        setting will be printed to the console.
        0 = emergency only, 7 = debug (everything).
      '';
    };

    boot.kernelPatches = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      example = literalExpression ''
        [
          {
            name = "my-patch";
            patch = ./my-fix.patch;
          }
        ]
      '';
      description = ''
        Additional patches to apply to the kernel.

        Each element should be an attribute set with at least a
        name and patch attribute. See the kernel build infrastructure
        for supported attributes.
      '';
    };

    boot.resumeDevice = mkOption {
      type = types.str;
      default = "";
      example = "/dev/sda3";
      description = ''
        Device for resume from hibernation (suspend-to-disk).

        This should be the swap partition or file used for hibernation.
        The kernel resume parameter will be set automatically.
      '';
    };

    boot.hardwareScan = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to try to load kernel modules for all detected hardware.

        Usually this does a good job of providing you with the modules
        you need, but sometimes it can crash the system or cause other
        nasty effects.
      '';
    };

    system.boot.loader.kernelFile = mkOption {
      type = types.str;
      internal = true;
      default = config.boot.kernelPackages.kernel.target;
      description = ''
        Name of the kernel file in the kernel package.
        Usually "bzImage" for x86_64, "Image" for ARM.
      '';
    };
  };

  config = mkMerge [
    # Set kernel console log level
    (mkIf (config.boot.consoleLogLevel != 4) {
      boot.kernelParams = [ "loglevel=${toString config.boot.consoleLogLevel}" ];
    })

    # Set resume device for hibernation
    (mkIf (config.boot.resumeDevice != "") {
      boot.kernelParams = [ "resume=${config.boot.resumeDevice}" ];
    })
  ];
}
