# Adios port of ekaos/modules/virtualisation/qemu-vm.nix.
#
# Tree path: virtualisation/qemu-vm is parent.virtualisation."qemu-vm".
# QEMU VM build targets (disk image + run script) for testing bootable
# systems. Reads the system label via inputs.toplevel
# (parent.system.toplevel, option ekaos.label).
# TODO(adios-cutover): HELPER GAP (load-bearing).
# ekaos/lib/make-disk-image.nix takes `{ pkgs, lib, config, ... }` with
# the GLOBAL config fixpoint; it needs an adios-aware rewrite owned
# outside this batch. The call below keeps the legacy argument shape with
# the specific known inputs wired (label, disk size, kernel console
# fragment) and passes pkgs.lib for lib; evaluation fails until the
# helper is rewritten.
# TODO(adios-cutover): build.diskImage / build.vm had no legacy defaults
# (internal outputs); no defaults here either (values come from impl).
# internal dropped.
{ types, pkgs, ... }:

let
  # Disk image builder (pkgs + lib closed over; ekaos inputs as params).
  mkDiskImage =
    { label, diskSize }:
    import ../../../lib/make-disk-image.nix {
      inherit pkgs;
      lib = pkgs.lib;
      config = {
        system.ekaos = {
          inherit label;
        };
        virtualisation.diskSize = diskSize;
      };

      format = "qcow2";
      partitionTableType = "efi";
      diskSize = toString diskSize;
      additionalSpace = "512M";
      installBootLoader = true;
      touchEFIVars = false; # LKL doesn't support EFI, vars created at runtime
      inherit label;
    };

  # QEMU run-script builder.
  mkRunVm =
    {
      label,
      memorySize,
      cores,
      enableNetwork,
      serialConsole,
      displayType,
      qemuOptions,
      diskImage,
    }:
    pkgs.writeScript "run-${label}-vm" ''
      #!${pkgs.runtimeShell}
      set -e

      # Paths
      DISK_IMAGE="${diskImage}/ekaos.qcow2"
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
        -name "${label}"
        -m ${toString memorySize}
        -smp ${toString cores}
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
      ${
        if enableNetwork then
          ''
            QEMU_OPTS+=(
              -device virtio-net-pci,netdev=net0
              -netdev user,id=net0
            )
          ''
        else
          ""
      }

      # Serial console
      ${
        if serialConsole then
          ''
            QEMU_OPTS+=(
              -serial mon:stdio
              -nographic
            )
          ''
        else
          ""
      }

      # Graphics (if not using serial console)
      ${
        if (!serialConsole) then
          ''
            QEMU_OPTS+=(
              -vga std
              -display ${displayType}
            )
          ''
        else
          ""
      }

      # Additional QEMU options
      ${qemuOptions}

      echo "Starting ekaos VM..."
      echo "Disk: $DISK_IMAGE"
      echo "EFI Vars: $EFI_VARS"
      echo ""

      exec ${pkgs.qemu}/bin/qemu-system-x86_64 "''${QEMU_OPTS[@]}"
    '';
in

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Enable VM build targets.";
    };

    memorySize = {
      type = types.int;
      default = 2048;
      description = "Memory size in MB for the VM.";
    };

    cores = {
      type = types.int;
      default = 2;
      description = "Number of CPU cores for the VM.";
    };

    diskSize = {
      type = types.int;
      default = 8192;
      description = "Disk size in MB.";
    };

    enableNetwork = {
      type = types.bool;
      default = true;
      description = "Enable network in the VM (user-mode networking).";
    };

    serialConsole = {
      type = types.bool;
      default = true;
      description = ''
        Use serial console instead of graphical display.
        Useful for headless testing.
      '';
    };

    displayType = {
      type = types.string;
      default = "gtk";
      description = "QEMU display type (gtk, sdl, vnc, etc.).";
    };

    qemuOptions = {
      type = types.string;
      default = "";
      example = ''
        QEMU_OPTS+=(-cdrom /path/to/cd.iso)
      '';
      description = "Additional QEMU command line options.";
    };

    build = {
      description = "VM build outputs.";
      options = {
        diskImage = {
          type = types.derivation;
          description = "QEMU disk image for the system.";
        };

        vm = {
          type = types.derivation;
          description = "Script to run the system in a VM.";
        };
      };
    };
  };

  inputs = {
    toplevel.from = { root }: root.system.toplevel;
  };

  impl =
    { options, inputs }:
    if !options.enable then
      { }
    else
      let
        label = inputs.toplevel.ekaos.label;
        diskImage = mkDiskImage {
          inherit label;
          diskSize = options.diskSize;
        };
      in
      {
        # Ensure serial console is configured in kernel params
      }
      // (
        if options.serialConsole then
          {
            boot.kernelParams = [
              "console=ttyS0,115200"
              "console=tty1"
            ];
          }
        else
          { }
      )
      // {
        # Build targets for VM
        system.build = {
          inherit diskImage;
          vm = mkRunVm {
            inherit label diskImage;
            inherit (options)
              memorySize
              cores
              enableNetwork
              serialConsole
              displayType
              qemuOptions
              ;
          };
        };
      };
}
