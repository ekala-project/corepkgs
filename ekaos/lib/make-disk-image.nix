# Disk image builder for ekaos
# Wraps nixpkgs make-disk-image.nix for bootable ekaos systems

{ config
, lib
, pkgs
, nixpkgs ? /home/jon/projects/nixpkgs
, # Disk image format: "qcow2", "raw", "vdi", "vpc"
  format ? "qcow2"
, # Partition table type: "efi" (GPT + ESP), "legacy" (MBR), "hybrid", "none"
  partitionTableType ? "efi"
, # Disk size in MB, or "auto" to calculate from closure size
  diskSize ? "auto"
, # Additional space beyond closure size (when diskSize = "auto")
  additionalSpace ? "512M"
, # Install bootloader (runs installBootLoader script)
  installBootLoader ? true
, # Touch EFI variables file (creates efi-vars.fd)
  touchEFIVars ? true
, # Copy nixpkgs channel (usually not needed for ekaos)
  copyChannel ? false
, # Filesystem label
  label ? "ekaos"
, ...
}@args:

let
  # Import NixOS's make-disk-image.nix
  makeDiskImage = import "${nixpkgs}/nixos/lib/make-disk-image.nix";

  # Prepare arguments for make-disk-image
  # Remove our custom args and pass through the rest
  imageArgs = builtins.removeAttrs args [ "nixpkgs" ] // {
    inherit
      config
      lib
      pkgs
      format
      partitionTableType
      diskSize
      additionalSpace
      installBootLoader
      touchEFIVars
      copyChannel
      label
      ;

    # For UEFI boot, we need an ESP
    bootSize = if partitionTableType == "efi" then "256M" else null;

    # ekaos-specific: we don't need channels
    copyChannel = false;

    # ekaos uses systemd-boot, not GRUB
    # The installBootLoader script should be provided by config.system.build.installBootLoader
  };

in

makeDiskImage imageArgs
