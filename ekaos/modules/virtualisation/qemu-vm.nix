# QEMU VM configuration for ekaos
# Simplified VM module for testing bootable systems

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.virtualisation;

  # Build the disk image
  diskImage = import ../../lib/make-disk-image.nix {
    inherit config lib pkgs;

    format = "qcow2";
    partitionTableType = "efi";
    diskSize = toString cfg.diskSize;
    additionalSpace = "512M";
    installBootLoader = true;
    touchEFIVars = false; # LKL doesn't support EFI, vars created at runtime
    label = config.system.ekaos.label;
  };

  # QEMU command builder
  qemuCmd = ''
    #!${pkgs.runtimeShell}
    set -e

    # Paths
    DISK_IMAGE="${diskImage}/nixos.qcow2"
    EFI_VARS_TEMPLATE="${diskImage}/efi-vars.fd"
    OVMF_CODE="${pkgs.OVMF.firmware}"

    # Check if disk image exists
    if [ ! -f "$DISK_IMAGE" ]; then
      echo "Error: Disk image not found at $DISK_IMAGE"
      exit 1
    fi

    # Create a writable copy of EFI vars in /tmp
    # (EFI vars must be writable, but files in /nix/store are read-only)
    EFI_VARS_DIR=$(mktemp -d /tmp/ekaos-efi-vars.XXXXXX)
    EFI_VARS="$EFI_VARS_DIR/efi-vars.fd"

    if [ -f "$EFI_VARS_TEMPLATE" ]; then
      cp "$EFI_VARS_TEMPLATE" "$EFI_VARS"
      chmod u+w "$EFI_VARS"
    else
      # If template doesn't exist, create an empty EFI vars file
      # using OVMF's vars template
      cp "${pkgs.OVMF.variables}" "$EFI_VARS"
      chmod u+w "$EFI_VARS"
    fi

    # Cleanup on exit
    trap "rm -rf $EFI_VARS_DIR" EXIT

    # QEMU arguments
    QEMU_OPTS=(
      -name "${config.system.ekaos.label}"
      -m ${toString cfg.memorySize}
      -smp ${toString cfg.cores}
      -machine type=q35,accel=kvm:tcg
      -cpu max
    )

    # UEFI firmware (pflash drives)
    QEMU_OPTS+=(
      -drive if=pflash,format=raw,unit=0,readonly=on,file="$OVMF_CODE"
      -drive if=pflash,format=raw,unit=1,file="$EFI_VARS"
    )

    # Main disk (snapshot mode for read-only nix store files)
    QEMU_OPTS+=(
      -drive file="$DISK_IMAGE",if=none,id=drive0,format=qcow2,snapshot=on
      -device virtio-blk-pci,drive=drive0
    )

    # Network (user-mode)
    ${optionalString cfg.enableNetwork ''
      QEMU_OPTS+=(
        -device virtio-net-pci,netdev=net0
        -netdev user,id=net0
      )
    ''}

    # Serial console
    ${optionalString cfg.serialConsole ''
      QEMU_OPTS+=(
        -serial mon:stdio
        -nographic
      )
    ''}

    # Graphics (if not using serial console)
    ${optionalString (!cfg.serialConsole) ''
      QEMU_OPTS+=(
        -vga std
        -display ${cfg.displayType}
      )
    ''}

    # Additional QEMU options
    ${cfg.qemuOptions}

    echo "Starting ekaos VM..."
    echo "Disk: $DISK_IMAGE"
    echo "EFI Vars: $EFI_VARS"
    echo ""

    exec ${pkgs.qemu}/bin/qemu-system-x86_64 "''${QEMU_OPTS[@]}"
  '';

  runVM = pkgs.writeScript "run-${config.system.ekaos.label}-vm" qemuCmd;

in

{
  options = {
    virtualisation = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable VM build targets.";
      };

      memorySize = mkOption {
        type = types.int;
        default = 2048;
        description = "Memory size in MB for the VM.";
      };

      cores = mkOption {
        type = types.int;
        default = 2;
        description = "Number of CPU cores for the VM.";
      };

      diskSize = mkOption {
        type = types.int;
        default = 8192;
        description = "Disk size in MB.";
      };

      enableNetwork = mkOption {
        type = types.bool;
        default = true;
        description = "Enable network in the VM (user-mode networking).";
      };

      serialConsole = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Use serial console instead of graphical display.
          Useful for headless testing.
        '';
      };

      displayType = mkOption {
        type = types.str;
        default = "gtk";
        description = "QEMU display type (gtk, sdl, vnc, etc.).";
      };

      qemuOptions = mkOption {
        type = types.lines;
        default = "";
        description = "Additional QEMU command line options.";
        example = ''
          QEMU_OPTS+=(-cdrom /path/to/cd.iso)
        '';
      };
    };

    system.build.diskImage = mkOption {
      type = types.package;
      internal = true;
      description = "QEMU disk image for the system.";
    };

    system.build.vm = mkOption {
      type = types.package;
      internal = true;
      description = "Script to run the system in a VM.";
    };
  };

  config = mkIf cfg.enable {
    # Ensure serial console is configured in kernel params
    boot.kernelParams = mkIf cfg.serialConsole [
      "console=ttyS0,115200"
      "console=tty1"
    ];

    # Build targets for VM
    system.build = {
      diskImage = diskImage;
      vm = runVM;
    };
  };
}
