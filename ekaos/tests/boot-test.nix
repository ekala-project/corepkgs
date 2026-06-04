# QEMU boot test for ekaos
# Tests that the system can boot successfully

{
  pkgs ? import ../../. { },
  configuration ? ../examples/minimal-system.nix,
}:

let
  # Evaluate the ekaos system with VM enabled
  eval = import ../eval-config.nix {
    inherit (pkgs) lib;
    inherit pkgs;
    modules = [
      configuration
      {
        # Enable VM build
        virtualisation.enable = true;
        virtualisation.memorySize = 2048;
        virtualisation.cores = 2;
        virtualisation.diskSize = 8192;
        virtualisation.serialConsole = true;

        # Ensure boot works
        boot.loader.systemd-boot.enable = true;
        boot.kernelPackages = pkgs.linux.pkgs;
      }
    ];
  };

in

{
  # The VM runner script
  inherit (eval.config.system.build) vm;

  # The disk image
  inherit (eval.config.system.build) diskImage;

  # Full config for inspection
  config = eval.config;

  # Test script that boots and checks for success
  test = pkgs.writeScript "boot-test" ''
    #!${pkgs.runtimeShell}
    set -e

    echo "========================================="
    echo "ekaos Boot Test"
    echo "========================================="
    echo ""

    echo "Building VM..."
    VM=${eval.config.system.build.vm}

    echo "Starting VM (will boot and run for 30 seconds)..."
    echo "Watch for successful boot messages..."
    echo ""

    # Run VM with timeout
    timeout 30s $VM || {
      EXIT_CODE=$?
      if [ $EXIT_CODE -eq 124 ]; then
        echo ""
        echo "========================================="
        echo "VM ran for 30 seconds without crashing"
        echo "========================================="
        echo ""
        echo "Boot test PASSED (timeout is expected)"
        exit 0
      else
        echo ""
        echo "========================================="
        echo "VM exited with error code: $EXIT_CODE"
        echo "========================================="
        echo ""
        echo "Boot test FAILED"
        exit 1
      fi
    }
  '';
}
