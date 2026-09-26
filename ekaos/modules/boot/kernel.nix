# Adios port of ekaos/modules/boot/kernel.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:

{
  options = {
    kernelPackages = {
      # TODO(adios-cutover): legacy type is types.unspecified; korora has no equivalent.
      type = types.any;
      default = pkgs.linux.pkgs;
      description = ''
        Kernel package set to use for the system.

        This determines which Linux kernel version will be used
        and provides access to kernel modules.
      '';
    };

    kernelParams = {
      type = types.listOf types.string;
      default = [ ];
      example = [
        "quiet"
        "splash"
      ];
      description = ''
        Kernel command line parameters.

        These are passed to the kernel at boot time.
      '';
    };

    kernelModules = {
      type = types.listOf types.string;
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

    extraModulePackages = {
      type = types.listOf types.derivation;
      default = [ ];
      description = ''
        Additional kernel module packages to include.

        These are merged into the kernel module search path alongside
        the modules from the selected kernel.
      '';
    };

    consoleLogLevel = {
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

    kernelPatches = {
      type = types.listOf types.attrs;
      default = [ ];
      description = ''
        Additional patches to apply to the kernel.

        Each element should be an attribute set with at least a
        name and patch attribute. See the kernel build infrastructure
        for supported attributes.
      '';
    };

    resumeDevice = {
      type = types.string;
      default = "";
      example = "/dev/sda3";
      description = ''
        Device for resume from hibernation (suspend-to-disk).

        This should be the swap partition or file used for hibernation.
        The kernel resume parameter will be set automatically.
      '';
    };

    hardwareScan = {
      type = types.bool;
      default = true;
      description = ''
        Whether to try to load kernel modules for all detected hardware.

        Usually this does a good job of providing you with the modules
        you need, but sometimes it can crash the system or cause other
        nasty effects.
      '';
    };

    # Legacy path: system.boot.loader.kernelFile (internal option).
    kernelFile = {
      type = types.string;
      # Legacy was internal = true; dropped (noted as load-bearing: consumers
      # must not override this, it tracks the kernel package layout).
      defaultFunc = { options, ... }: options.kernelPackages.kernel.target;
      description = ''
        Name of the kernel file in the kernel package.
        Usually "bzImage" for x86_64, "Image" for ARM.
      '';
    };
  };

  assertions = [
    {
      verify = { options, ... }: options.consoleLogLevel >= 0 && options.consoleLogLevel <= 7;
      explain = { options, ... }: "consoleLogLevel must be 0-7, got ${toString options.consoleLogLevel}";
    }
  ];

  impl =
    { options, ... }:
    {
      boot = {
        # NOTE: kernelPackages is deliberately NOT part of the fragment: it
        # is a giant package set containing repo-broken members, and merging
        # it strictly would poison the whole config. Consumers read it via
        # inputs (this module's option), never from merged config.
        inherit (options)
          kernelModules
          extraModulePackages
          kernelPatches
          resumeDevice
          hardwareScan
          consoleLogLevel
          ;
        kernelParams =
          options.kernelParams
          ++ (
            if options.consoleLogLevel != 4 then [ "loglevel=${toString options.consoleLogLevel}" ] else [ ]
          )
          ++ (if options.resumeDevice != "" then [ "resume=${options.resumeDevice}" ] else [ ]);
      };
      system.boot.loader = {
        inherit (options) kernelFile;
      };
    };
}
