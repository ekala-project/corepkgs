# Adios port of ekaos/modules/boot/initrd.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:

let
  # The initramfs derivation plus the effective module lists derived from
  # options. Shared by the `initrd` option (so system/toplevel can read it
  # through an adios input) and by impl.
  buildInitrd =
    {
      options,
      inputs ? { },
    }:
    if !options.enable then
      {
        availableKernelModules = [ ];
        kernelModules = [ ];
        initrd = null;
      }
    else
      let
        # Legacy appended these to its own options via list merging; the
        # effective (user ++ automatic) lists are computed here.
        defaultModules =
          if options.includeDefaultModules then
            [
              # SATA/PATA
              "ahci"
              "ata_piix"
              "sata_nv"
              "sata_via"

              # NVMe
              "nvme"

              # USB
              "xhci_pci"
              "ehci_pci"
              "uhci_hcd"
              "usb_storage"
              "sd_mod"

              # VirtIO (for VMs)
              "virtio_blk"
              "virtio_pci"
              "virtio_scsi"
            ]
          else
            [ ];
        availableKernelModules = options.availableKernelModules ++ defaultModules;

        fsModules =
          (if builtins.elem "ext4" options.supportedFilesystems then [ "ext4" ] else [ ])
          ++ (if builtins.elem "btrfs" options.supportedFilesystems then [ "btrfs" ] else [ ])
          ++ (if builtins.elem "xfs" options.supportedFilesystems then [ "xfs" ] else [ ])
          ++ (
            if builtins.elem "vfat" options.supportedFilesystems then
              [
                "vfat"
                "nls_cp437"
                "nls_iso8859-1"
              ]
            else
              [ ]
          );
        luksModules =
          if options.luksDevices != { } then
            [
              "dm-crypt"
              "dm-mod"
              "aes"
              "sha256"
              "sha512"
            ]
          else
            [ ];
        kernelModules = options.kernelModules ++ fsModules ++ luksModules;

        initrd = import ../../lib/make-initrd.nix {
          inherit availableKernelModules kernelModules;
          inherit (options)
            compressor
            extraUtilsCommands
            preLVMCommands
            postDeviceCommands
            postMountCommands
            supportedFilesystems
            ;
          luks = {
            devices = options.luksDevices;
          };
          inherit pkgs;
          kernelPackages = (inputs.kernel.kernelPackages or pkgs.linux.pkgs);
        };
      in
      {
        inherit availableKernelModules kernelModules initrd;
      };
in

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable initramfs (initial ramdisk).

        When enabled, the system boots through a two-stage process:
        1. Stage-1: Initramfs mounts root and loads modules
        2. Stage-2: Real init (systemd) starts

        Required for encrypted/LVM/RAID/network root filesystems.
      '';
    };

    availableKernelModules = {
      type = types.listOf types.string;
      default = [ ];
      example = [
        "ahci"
        "xhci_pci"
        "nvme"
        "usb_storage"
        "sd_mod"
      ];
      description = ''
        Kernel modules to include in the initramfs.

        These modules are loaded during stage-1 boot to support
        hardware needed to access the root filesystem.
      '';
    };

    kernelModules = {
      type = types.listOf types.string;
      default = [ ];
      example = [
        "dm-crypt"
        "dm-mod"
      ];
      description = ''
        Additional kernel modules to load in initramfs.

        Loaded after availableKernelModules.
      '';
    };

    # Legacy path: boot.initrd.luks.devices.
    luksDevices = {
      type = types.attrsOf types.attrs;
      # TODO(adios-cutover): submodule validation lost. Each entry supports:
      # device (string, required), name (string, default ""), keyFile
      # (null or string, default null), allowDiscards (bool, default false).
      default = { };
      description = ''
        LUKS encrypted devices to unlock during stage-1.

        Each device will be unlocked and made available as
        /dev/mapper/<name> before mounting root.
      '';
    };

    supportedFilesystems = {
      type = types.listOf types.string;
      default = [
        "ext4"
        "vfat"
      ];
      example = [
        "ext4"
        "btrfs"
        "xfs"
        "vfat"
      ];
      description = ''
        Filesystem types to support in initramfs.

        Tools for these filesystems will be included.
      '';
    };

    extraUtilsCommands = {
      type = types.string;
      default = "";
      description = ''
        Additional commands to run when building initramfs utilities.

        Use this to copy additional binaries into the initramfs.
      '';
    };

    preLVMCommands = {
      type = types.string;
      default = "";
      description = ''
        Shell commands to run in stage-1 before LVM activation.
      '';
    };

    postDeviceCommands = {
      type = types.string;
      default = "";
      description = ''
        Shell commands to run after device initialization.
      '';
    };

    postMountCommands = {
      type = types.string;
      default = "";
      description = ''
        Shell commands to run after mounting root filesystem.
      '';
    };

    compressor = {
      type = types.string;
      default = "gzip";
      example = "zstd";
      description = ''
        Compression program for the initramfs.

        Options: gzip, bzip2, xz, zstd, lz4, lzop
      '';
    };

    includeDefaultModules = {
      type = types.bool;
      default = true;
      description = ''
        Include a default set of kernel modules for common hardware.

        Includes modules for SATA, USB, NVMe, and common filesystems.
      '';
    };

    # Exposed as an option (not only in impl) so system/toplevel can consume
    # it through an adios input: inputs see sibling OPTIONS, never impl
    # results.
    initrd = {
      type = types.nullOr types.derivation;
      defaultFunc = { options, inputs }: (buildInitrd { inherit options inputs; }).initrd;
      description = ''
        The initial ramdisk (stage-1) derivation.

        Null when boot.initrd.enable is false.
        Read-only output; value comes from the defaultFunc.
      '';
    };
  };

  inputs = {
    kernel.from = { parent }: parent.kernel;
  };

  impl =
    { options, inputs }:
    if !options.enable then
      { }
    else
      let
        built = buildInitrd { inherit options inputs; };
      in
      {
        boot.initrd = {
          inherit (built) availableKernelModules kernelModules;
        };

        # Legacy internal options system.build.initrd / .initialRamdisk.
        system.build.initrd = built.initrd;
        system.build.initialRamdisk = built.initrd;
      };
}
