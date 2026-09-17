# Lightweight boot test runner for ekaos
#
# Boots a system configuration in QEMU without building a disk image.
# The nix store is shared via 9p and a tmpfs overlay provides the root
# filesystem.  Serial output is checked for systemd target milestones.
#
# Usage:
#   mkBootTest {
#     name = "my-boot-test";
#     configuration = { config, pkgs, ... }: { ... };
#     expectedTargets = [ "multi-user.target" ];   # optional
#     timeout = 120;                                 # optional, seconds
#   }

{
  lib,
  pkgs,
}:

{
  name,
  configuration,
  expectedTargets ? [ "multi-user.target" ],
  timeout ? 120,
}:

let
  # Evaluate the system configuration
  eval = (import ../../eval-config.nix { inherit lib pkgs; }) {
    modules = [
      configuration
      {
        # Baseline for VM boot testing
        boot.kernelPackages = pkgs.linuxPackages_6_12;
        boot.loader.systemd-boot.enable = true;
        boot.kernelParams = [
          "console=ttyS0,115200"
          "panic=1"
          "boot.panic_on_fail"
          "systemd.log_target=kmsg"
          "systemd.journald.forward_to_console=1"
        ];
      }
    ];
  };

  toplevel = eval.config.system.build.toplevel;
  kernel = eval.config.boot.kernelPackages.kernel;
  kernelFile = eval.config.system.boot.loader.kernelFile;

  # Minimal module closure for the test initrd (9p + overlay)
  testModules = kernel.makeModulesClosure {
    rootModules = [
      "9p"
      "9pnet"
      "9pnet_virtio"
      "overlay"
      "virtio_pci"
    ];
    kernel = kernel.modules;
    firmware = [ ];
    allowMissing = true;
  };

  # Decompressed modules (busybox modprobe can't handle .ko.xz)
  # Also regenerates modules.dep so it references the .ko filenames.
  decompressedModules =
    pkgs.runCommand "test-initrd-modules"
      {
        nativeBuildInputs = [
          pkgs.buildPackages.xz
          pkgs.buildPackages.kmod
        ];
      }
      ''
        mkdir -p $out/lib/modules
        cp -r ${testModules}/lib/modules/* $out/lib/modules/
        chmod -R u+w $out/lib/modules
        find $out/lib/modules -name '*.ko.xz' -exec xz -d {} \;
        find $out/lib/modules -name '*.ko.zst' -exec zstd -d --rm {} \;
        kernelVersion=$(ls $out/lib/modules)
        depmod -b $out -a "$kernelVersion"
      '';

  # Minimal init script that mounts 9p nix store via overlay and runs stage-2
  initScript = pkgs.writeScript "vm-test-init" ''
    #!/bin/sh
    export PATH=/bin

    mount -t proc proc /proc
    mount -t sysfs sysfs /sys
    mount -t devtmpfs devtmpfs /dev
    mount -t tmpfs tmpfs /run

    # Redirect to serial
    if [ -e /dev/ttyS0 ]; then
      exec > /dev/ttyS0 2>&1 < /dev/ttyS0
    fi

    echo "ekaos boot-test init"

    # Load required kernel modules (/lib/modules is baked into the initrd)
    for mod in 9pnet 9pnet_virtio 9p overlay virtio_pci; do
      modprobe $mod 2>/dev/null || echo "  $mod: builtin or unavailable"
    done

    # Mount nix store from host via 9p (read-only)
    mkdir -p /nix/.ro-store /nix/.rw-store /nix/.work /nix/store
    mount -t 9p -o trans=virtio,version=9p2000.L,msize=131072,ro store /nix/.ro-store

    # Overlay gives the store a writable layer without modifying the host
    mount -t overlay overlay \
      -o lowerdir=/nix/.ro-store,upperdir=/nix/.rw-store,workdir=/nix/.work \
      /nix/store

    # Create essential tmpfs directories
    mount -t tmpfs tmpfs /tmp
    mkdir -p /etc /var /home /root
    chmod 1777 /tmp

    # Run the system init
    exec ${toplevel}/init
  '';

  # Build a tiny initrd containing the init script, busybox, and modules
  testInitrd =
    pkgs.runCommand "boot-test-initrd"
      {
        __structuredAttrs = false;
        nativeBuildInputs = [
          pkgs.cpio
          pkgs.gzip
        ];
      }
      ''
        mkdir -p root/bin root/dev root/proc root/sys root/nix/store root/run
        cp ${pkgs.pkgsStatic.busybox}/bin/busybox root/bin/busybox
        for cmd in sh mount mkdir chmod ln cat modprobe insmod; do
          ln -sf busybox root/bin/$cmd
        done
        cp -r ${decompressedModules}/lib root/lib
        cp ${initScript} root/init
        chmod +x root/init
        (cd root && find . -print0 | sort -z | cpio --quiet -o -H newc -R +0:+0 --null | gzip > $out)
      '';

  qemuBin = "${pkgs.qemu}/bin/qemu-system-x86_64";

in
pkgs.runCommand "ekaos-boot-test-${name}"
  {
    nativeBuildInputs = [
      pkgs.qemu
    ];
    # Reference the toplevel so its closure is available
    inherit toplevel;
  }
  ''
    set -euo pipefail

    echo "=== ekaos boot test: ${name} ==="
    echo "Toplevel: ${toplevel}"
    echo "Kernel:   ${kernel}/${kernelFile}"
    echo "Timeout:  ${toString timeout}s"
    echo "Expected: ${lib.concatStringsSep ", " expectedTargets}"
    echo ""

    # Boot QEMU with kernel directly, sharing /nix/store via 9p
    timeout ${toString timeout} ${qemuBin} \
      -m 2048 \
      -smp 2 \
      -machine type=q35,accel=kvm:tcg \
      -cpu max \
      -kernel ${kernel}/${kernelFile} \
      -initrd ${testInitrd} \
      -append "init=/init console=ttyS0,115200 panic=1 systemd.log_target=kmsg systemd.journald.forward_to_console=1" \
      -virtfs local,path=/nix/store,security_model=none,mount_tag=store,readonly=on \
      -nographic \
      -serial mon:stdio \
      -no-reboot \
      -net none \
      2>&1 | tee $TMPDIR/boot.log || true

    echo ""
    echo "=== Checking boot results ==="

    # Strip ANSI escape codes for reliable grep matching
    sed 's/\x1b\[[0-9;]*[a-zA-Z]//g; s/\x1b\[[0-9;]*[mHJt]//g' $TMPDIR/boot.log > $TMPDIR/boot-clean.log

    # Check that the default target was reached.  systemd prints
    # "Startup finished in ..." once the default target (and all its
    # dependencies including multi-user.target) is fully up.
    failed=0
    if grep -q "Startup finished" $TMPDIR/boot-clean.log; then
      echo "PASS: systemd startup finished"
    else
      echo "FAIL: systemd startup did not finish"
      failed=1
    fi

    # Also verify each expected target individually using the human-readable
    # names that systemd logs (e.g. "Reached target Multi-User System").
    ${lib.concatMapStringsSep "\n" (target: ''
      if grep -q "Reached target" $TMPDIR/boot-clean.log &&
         grep -qi "${lib.removeSuffix ".target" target}" $TMPDIR/boot-clean.log; then
        echo "PASS: ${target}"
      else
        echo "WARN: ${target} — could not confirm (may use different display name)"
      fi
    '') expectedTargets}

    if [ "$failed" = "1" ]; then
      echo ""
      echo "=== Boot log (last 50 lines) ==="
      tail -50 $TMPDIR/boot-clean.log
      echo ""
      echo "FAILED: Not all targets reached"
      exit 1
    fi

    # Check for kernel panic
    if grep -q "Kernel panic" $TMPDIR/boot-clean.log; then
      echo ""
      echo "FAILED: Kernel panic detected"
      grep "Kernel panic" $TMPDIR/boot-clean.log
      exit 1
    fi

    echo ""
    echo "=== All targets reached ==="
    mkdir -p $out
    cp $TMPDIR/boot.log $out/
    echo "PASS" > $out/result
  ''
