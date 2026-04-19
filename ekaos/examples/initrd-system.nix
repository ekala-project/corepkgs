# Example ekaos system configuration with initrd/initramfs support
# Demonstrates two-stage boot process

{ config, lib, pkgs, ... }:

{
  # System identification
  system.ekaos.version = "24.11";
  system.ekaos.label = "ekaos-initrd-example";

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # Kernel configuration
  boot.kernelPackages = pkgs.linuxPackages;

  # Kernel parameters
  boot.kernelParams = [
    "console=ttyS0,115200"  # Serial console
    "console=tty1"           # VGA console
    "quiet"
  ];

  # Enable initramfs for two-stage boot
  boot.initrd = {
    enable = true;

    # Kernel modules to load in stage-1
    availableKernelModules = [
      # SATA controllers
      "ahci" "ata_piix"

      # NVMe
      "nvme"

      # USB
      "xhci_pci" "ehci_pci"
      "usb_storage" "sd_mod"

      # VirtIO (for VMs)
      "virtio_blk" "virtio_pci"
    ];

    # Additional modules
    kernelModules = [
      "ext4"  # Root filesystem
    ];

    # Supported filesystems
    supportedFilesystems = [ "ext4" "vfat" ];

    # Compression (options: gzip, xz, zstd, lz4)
    compressor = "gzip";

    # Example: LUKS encryption (commented out)
    # luks.devices = {
    #   root = {
    #     device = "/dev/vda2";
    #     name = "cryptroot";
    #     allowDiscards = true;  # Enable TRIM for SSDs
    #   };
    # };

    # Custom commands during boot
    postDeviceCommands = ''
      echo "Stage-1: Devices initialized"
    '';

    postMountCommands = ''
      echo "Stage-1: Root filesystem mounted"
    '';
  };

  # Essential system packages
  environment.systemPackages = with pkgs; [
    coreutils
    util-linux
    systemd
  ];

  # Example service
  systemd.services.boot-marker = {
    enable = true;
    description = "Initrd Boot Marker Service";
    command = "${pkgs.coreutils}/bin/echo";
    args = [
      "========================================="
      "ekaos BOOTED WITH INITRD!"
      "Two-stage boot process complete"
      "Stage-1: initramfs → Stage-2: systemd"
      "========================================="
    ];

    systemd = {
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
    };
  };

  # Example /etc file
  environment.etc."initrd-enabled".text = ''
    This system uses initramfs for boot.

    Boot process:
    1. UEFI loads systemd-boot
    2. systemd-boot loads kernel + initrd
    3. Kernel unpacks initrd and runs stage-1 init
    4. Stage-1 loads modules, mounts root
    5. Stage-1 switches to real root
    6. Stage-2 init (systemd) starts
    7. System reaches multi-user.target
  '';
}
