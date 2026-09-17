# Initramfs (initrd) builder for ekaos
# Creates a minimal initial ramdisk for stage-1 boot

{
  pkgs,
  lib,
  kernelPackages,
  availableKernelModules ? [ ],
  kernelModules ? [ ],
  compressor ? "gzip",
  extraUtilsCommands ? "",
  preLVMCommands ? "",
  postDeviceCommands ? "",
  postMountCommands ? "",
  luks ? {
    devices = { };
  },
  supportedFilesystems ? [
    "ext4"
    "vfat"
  ],
}:

let
  inherit (lib) concatStringsSep optionalString;

  # Compression commands
  compressorExe =
    {
      gzip = "${pkgs.gzip}/bin/gzip";
      bzip2 = "${pkgs.bzip2}/bin/bzip2";
      xz = "${pkgs.xz}/bin/xz";
      zstd = "${pkgs.zstd}/bin/zstd";
      lz4 = "${pkgs.lz4}/bin/lz4";
      lzop = "${pkgs.lzop}/bin/lzop";
    }
    .${compressor} or "${pkgs.gzip}/bin/gzip";

  # All kernel modules to include
  allModules = availableKernelModules ++ kernelModules;

  # Build minimal utilities for initramfs
  extraUtils =
    pkgs.runCommand "initrd-utils"
      {
        __structuredAttrs = false;
        nativeBuildInputs = [
          pkgs.buildPackages.nukeReferences
          pkgs.buildPackages.patchelf
        ];
        allowedReferences = [ "out" ];
      }
      ''
        set +o pipefail

        mkdir -p $out/bin $out/lib

        # Copy statically-linked busybox (no dynamic linker needed in initrd)
        cp ${pkgs.pkgsStatic.busybox}/bin/busybox $out/bin/
        chmod u+w $out/bin/busybox

        # Create busybox symlinks for all needed applets
        for cmd in sh ash mkdir mknod switch_root cat cp mv rm ln chmod chown \
                   sleep echo test true false kill pidof ps grep sed awk cut sort uniq wc \
                   find xargs basename dirname readlink realpath pwd which env \
                   mount umount modprobe insmod lsmod rmmod; do
          ln -sf busybox $out/bin/$cmd
        done

        # Helper to copy a dynamically-linked binary and all its libraries
        copy_bin_and_libs() {
          local BIN="$1"
          cp "$BIN" $out/bin/
          chmod u+w "$out/bin/$(basename "$BIN")"

          # Copy the dynamic linker
          local INTERP=$(patchelf --print-interpreter "$BIN" 2>/dev/null) || INTERP=""
          if [ -n "$INTERP" ] && [ -f "$INTERP" ]; then
            cp -n "$INTERP" $out/lib/
            chmod u+w "$out/lib/$(basename "$INTERP")"
          fi

          # Copy shared libraries by resolving via ldd
          local LIBS=$(ldd "$BIN" 2>/dev/null | grep -o '/nix/store/[^ ]*') || LIBS=""
          for lib in $LIBS; do
            if [ -f "$lib" ]; then
              cp -n "$lib" $out/lib/
              chmod u+w "$out/lib/$(basename "$lib")"
            fi
          done
        }

        # Copy blkid for UUID-based root device lookup (no udev needed)
        copy_bin_and_libs ${pkgs.util-linux}/bin/blkid

        # Copy filesystem check tools (these need glibc, can't use busybox)
        ${optionalString (lib.elem "ext4" supportedFilesystems) ''
          copy_bin_and_libs ${pkgs.e2fsprogs}/bin/e2fsck
          ln -sf e2fsck $out/bin/fsck.ext4
        ''}

        ${optionalString (lib.elem "vfat" supportedFilesystems) ''
          copy_bin_and_libs ${pkgs.dosfstools}/bin/fsck.vfat
        ''}

        # Copy LUKS utilities if needed
        ${optionalString (luks.devices != { }) ''
          copy_bin_and_libs ${pkgs.cryptsetup}/bin/cryptsetup
        ''}

        # Extra utilities from configuration
        ${extraUtilsCommands}

        # Fix up dynamically-linked binaries to be self-contained:
        # set interpreter and RPATH to $out/lib, strip, nuke external refs,
        # then re-patch (nuke-refs destroys store hashes in the binary)
        patch_dynamic_bins() {
          local ldso=$(find $out/lib -name 'ld-linux-*.so.*' -o -name 'ld-*.so.*' 2>/dev/null | head -1)
          for bin in $out/bin/*; do
            [ -f "$bin" ] && [ ! -L "$bin" ] || continue
            # strip debug symbols (may fail on static binaries — that's fine)
            strip -s "$bin" 2>/dev/null || :
            # only patch ELF binaries that have a dynamic interpreter
            patchelf --print-interpreter "$bin" >/dev/null 2>&1 || continue
            if [ -n "$ldso" ]; then
              patchelf --set-interpreter "$ldso" --set-rpath $out/lib "$bin"
            fi
          done
        }

        patch_dynamic_bins
        find $out/lib -type f -exec strip -s {} \; 2>/dev/null || :

        # Nuke references to other store paths (self-references via $out are OK)
        nuke-refs $out/bin/* $out/lib/*

        # Re-patch after nuke-refs (which destroys store hashes)
        patch_dynamic_bins
      '';

  # Stage-1 init script
  bootStage1 = pkgs.writeScript "init" ''
    #!/bin/sh

    fail() {
      echo "FATAL: $1"
      echo "Dropping to emergency shell"
      exec /bin/sh
    }

    # Set up basic environment
    export PATH=/bin
    export LD_LIBRARY_PATH=/lib

    # Mount essential filesystems
    mount -t proc proc /proc
    mount -t sysfs sysfs /sys
    mount -t devtmpfs devtmpfs /dev
    mount -t tmpfs tmpfs /run

    # Redirect output to serial console if available
    if [ -e /dev/ttyS0 ]; then
      exec > /dev/ttyS0 2>&1 < /dev/ttyS0
    fi

    echo "ekaos stage-1 init starting..."

    # Create device nodes
    mkdir -p /dev/pts /dev/shm
    mount -t devpts devpts /dev/pts
    mount -t tmpfs tmpfs /dev/shm

    echo "Loading kernel modules..."
    # Set up /sbin/modprobe so the kernel's request_module() can auto-load dependencies
    mkdir -p /sbin
    ln -sf /bin/modprobe /sbin/modprobe
    # /lib/modules is a symlink to the module closure — modprobe finds them at /lib/modules/VERSION/
    ${concatStringsSep "\n" (
      map (mod: ''
        modprobe ${mod} 2>/dev/null || echo "  ${mod}: not available"
      '') allModules
    )}

    # Wait for devices to settle
    sleep 1

    ${preLVMCommands}

    # Unlock LUKS devices
    ${concatStringsSep "\n" (
      lib.mapAttrsToList (name: dev: ''
        echo "Unlocking LUKS device ${dev.device}..."
        ${
          if dev.keyFile != null then
            "cryptsetup luksOpen ${dev.device} ${
              if dev.name != "" then dev.name else name
            } --key-file=${dev.keyFile} ${optionalString dev.allowDiscards "--allow-discards"}"
          else
            "cryptsetup luksOpen ${dev.device} ${
              if dev.name != "" then dev.name else name
            } ${optionalString dev.allowDiscards "--allow-discards"}"
        }
      '') luks.devices
    )}

    ${postDeviceCommands}

    # Find and mount root filesystem
    echo "Mounting root filesystem..."
    mkdir -p /mnt-root

    # Parse root= from kernel command line
    ROOT_DEVICE=""
    ROOT_UUID=""
    for param in $(cat /proc/cmdline); do
      case "$param" in
        root=UUID=*)
          ROOT_UUID="''${param#root=UUID=}"
          ;;
        root=PARTUUID=*)
          ROOT_DEVICE="/dev/disk/by-partuuid/''${param#root=PARTUUID=}"
          ;;
        root=LABEL=*)
          ROOT_DEVICE="/dev/disk/by-label/''${param#root=LABEL=}"
          ;;
        root=/dev/*)
          ROOT_DEVICE="''${param#root=}"
          ;;
      esac
    done

    if [ -e /dev/mapper/cryptroot ]; then
      ROOT_DEVICE="/dev/mapper/cryptroot"
      ROOT_UUID=""
    fi

    # Resolve UUID to device using blkid (no udev needed)
    if [ -n "$ROOT_UUID" ]; then
      echo "Looking for root filesystem UUID=$ROOT_UUID"
      # Try /dev/disk/by-uuid first (works if udev is available)
      if [ -e "/dev/disk/by-uuid/$ROOT_UUID" ]; then
        ROOT_DEVICE="/dev/disk/by-uuid/$ROOT_UUID"
      else
        # Scan block devices for matching UUID
        for dev in /dev/vda* /dev/sda* /dev/nvme*; do
          if [ -b "$dev" ]; then
            dev_uuid=$(blkid -s UUID -o value "$dev" 2>/dev/null)
            if [ "$dev_uuid" = "$ROOT_UUID" ]; then
              ROOT_DEVICE="$dev"
              echo "Found root device: $ROOT_DEVICE"
              break
            fi
          fi
        done
      fi
    fi

    # Fallback to common VM device
    if [ -z "$ROOT_DEVICE" ]; then
      ROOT_DEVICE="/dev/vda2"
    fi

    # Wait for root device to appear
    for i in $(busybox seq 1 30); do
      if [ -e "$ROOT_DEVICE" ]; then
        break
      fi
      echo "Waiting for $ROOT_DEVICE..."
      sleep 0.5
    done

    mount "$ROOT_DEVICE" /mnt-root || {
      echo "Failed to mount root filesystem on $ROOT_DEVICE"
      echo "Available block devices:"
      ls -l /dev/vd* /dev/sd* /dev/mapper/* 2>/dev/null
      echo "Dropping to emergency shell"
      exec /bin/sh
    }

    ${postMountCommands}

    echo "Switching to real root..."
    # Create mount points on root filesystem if they don't exist
    mkdir -p /mnt-root/proc /mnt-root/sys /mnt-root/dev /mnt-root/run /mnt-root/tmp

    # Move mounts to new root
    mount --move /proc /mnt-root/proc
    mount --move /sys /mnt-root/sys
    mount --move /dev /mnt-root/dev
    mount --move /run /mnt-root/run

    # Parse init= from kernel command line to find the real init
    REAL_INIT="/init"
    for param in $(cat /mnt-root/proc/cmdline); do
      case "$param" in
        init=*)
          REAL_INIT="''${param#init=}"
          ;;
      esac
    done

    echo "Executing $REAL_INIT..."
    exec switch_root /mnt-root "$REAL_INIT" || fail "switch_root failed"
  '';

  # Build a minimal closure of only the needed kernel modules
  modulesTree = kernelPackages.kernel.makeModulesClosure {
    rootModules = allModules;
    kernel = kernelPackages.kernel.modules;
    firmware = [ ];
    allowMissing = true;
  };

  # Decompressed kernel modules tree for busybox modprobe (which lacks xz support).
  # Output: $out/modules/VERSION/{kernel/..., modules.dep, ...}
  decompressedModules =
    pkgs.runCommand "initrd-modules"
      {
        nativeBuildInputs = [
          pkgs.buildPackages.xz
          pkgs.buildPackages.kmod
        ];
      }
      ''
        mkdir -p $out/modules
        cp -r ${modulesTree}/lib/modules/* $out/modules/
        chmod -R u+w $out/modules
        find $out/modules -name '*.ko.xz' -exec xz -d {} \;
        find $out/modules -name '*.ko.zst' -exec zstd -d --rm {} \;
        # Regenerate modules.dep for the decompressed .ko files
        # depmod -b BASE looks for BASE/lib/modules/VERSION
        mkdir -p $out/lib
        ln -sf $out/modules $out/lib/modules
        kernelVersion=$(ls $out/modules)
        depmod -b $out -a "$kernelVersion"
        rm $out/lib/modules
        rmdir $out/lib
      '';

  # Combined /lib directory with both shared libraries and kernel modules
  # This allows modprobe to find modules at the standard /lib/modules/VERSION/ path
  combinedLib = pkgs.runCommand "initrd-lib" { } ''
    mkdir -p $out
    # Symlink shared libraries from extraUtils
    for f in ${extraUtils}/lib/*; do
      ln -sf "$f" $out/
    done
    # Symlink decompressed kernel modules
    ln -sf ${decompressedModules}/modules $out/modules
  '';

in

kernelPackages.kernel.makeInitrd {
  contents = [
    {
      object = bootStage1;
      symlink = "/init";
    }
    {
      object = "${extraUtils}/bin";
      symlink = "/bin";
    }
    {
      object = combinedLib;
      symlink = "/lib";
    }
  ];

  compressor = compressorExe;
}
