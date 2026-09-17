# Example: Build and run an ekaos VM image
#
# Build the disk image:
#   nix-build -E '(import ./ekaos { system = "x86_64-linux"; modules = [ ./ekaos/examples/vm-image.nix ]; }).diskImage'
#
# Run the VM:
#   nix-build -E '(import ./ekaos { system = "x86_64-linux"; modules = [ ./ekaos/examples/vm-image.nix ]; }).vm'
#   ./result
#
# The disk image is a qcow2 file suitable for use with QEMU, libvirt, or
# other hypervisors. The VM script launches QEMU with EFI boot.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  system.ekaos.version = "24.11";
  system.ekaos.label = "ekaos-vm";

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # Initrd for loading virtio modules before root mount
  boot.initrd.enable = true;
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "ext4"
  ];

  # VM settings
  virtualisation.enable = true;
  virtualisation.memorySize = 2048;
  virtualisation.cores = 2;
  virtualisation.diskSize = 8192;
  virtualisation.serialConsole = true;

  # Serial console for VM
  boot.kernelParams = [
    "console=ttyS0,115200"
    "console=tty1"
    "root=UUID=F222513B-DED1-49FA-B591-20CE86A2FE7F"
  ];

  # Packages
  environment.systemPackages = with pkgs; [
    coreutils
    util-linux
    systemd
    bash
    less
    curl
  ];
}
