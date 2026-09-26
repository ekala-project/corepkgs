# Adios port of ekaos/modules/installer/installation-cd-base.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
#
# Legacy is a config-only module (no options of its own); it becomes an
# impl-only adios module.
{ pkgs, ... }:

{
  options = { };

  impl = { ... }: {
    # iso-image.nix is loaded for all system evaluations (disabled by
    # default). Flip the enable flag here.
    isoImage.enable = true;

    # Boot configuration
    boot.initrd.enable = true;
    boot.initrd.compressor = "zstd";

    # Broad hardware support for installation media
    boot.initrd.includeDefaultModules = true;
    boot.initrd.availableKernelModules = [
      # Additional storage controllers
      "sata_nv"
      "sata_via"
      "sata_sis"
      "pata_via"
      "ahci"
      "nvme"
      # USB
      "xhci_pci"
      "ehci_pci"
      "uhci_hcd"
      "usb_storage"
      "usbhid"
      "sd_mod"
      "sr_mod"
      # VirtIO
      "virtio_blk"
      "virtio_pci"
      "virtio_scsi"
      "virtio_net"
    ];

    # Filesystem support
    boot.initrd.supportedFilesystems = [
      "ext4"
      "btrfs"
      "xfs"
      "vfat"
    ];

    # Kernel parameters for live boot
    boot.kernelParams = [
      "boot.shell_on_fail"
    ];

    # Networking
    # TODO(adios-cutover): priority lost (was mkDefault).
    networking.networkmanager.enable = true;

    # Live user
    users.users.nixos = {
      isNormalUser = true;
      initialPassword = "";
      extraGroups = [
        "wheel"
        "networkmanager"
        "video"
        "audio"
      ];
      description = "Live User";
    };

    # Allow root login without password
    # TODO(adios-cutover): priority lost (was mkDefault).
    users.users.root.initialPassword = "";

    # Passwordless sudo for the live environment
    # TODO(adios-cutover): priority lost (was mkDefault).
    security.sudo.enable = true;
    security.sudo.wheelNeedsPassword = false;

    # Polkit — allow wheel group to do anything (needed for installers)
    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';

    # Essential packages available in corepkgs
    environment.systemPackages = with pkgs; [
      # Partitioning and filesystem tools
      parted
      gptfdisk
      e2fsprogs
      dosfstools
      cryptsetup

      # Hardware inspection
      pciutils

      # Editors
      nano

      # Utilities
      jq
      unzip
      zip
      rsync
      socat
    ];

    # Git for convenience
    # TODO(adios-cutover): priority lost (was mkDefault).
    programs.git.enable = true;

    # Enable SSH for headless installs
    # TODO(adios-cutover): priority lost (was mkDefault).
    services.openssh.enable = true;

    # Tell the Nix evaluator to garbage collect aggressively in low-memory
    # environments that don't have swap.
    environment.variables.GC_INITIAL_HEAP_SIZE = "1M";

    # Allow overcommit — installation processes fork heavily.
    # TODO(adios-cutover): priority lost (was mkDefault).
    boot.kernel.sysctl."vm.overcommit_memory" = "1";
  };
}
