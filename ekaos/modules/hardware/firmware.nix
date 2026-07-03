# Hardware firmware configuration
# Manages firmware blobs needed for hardware devices
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.hardware;

  # Combine all firmware into a single directory
  combinedFirmware = pkgs.buildEnv {
    name = "firmware";
    paths = cfg.firmware;
    pathsToLink = [ "/lib/firmware" ];
    ignoreCollisions = true;
  };

in

{
  options.hardware = {
    firmware = mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = literalExpression "[ pkgs.linux-firmware ]";
      description = ''
        List of firmware packages to make available to the kernel.
        These are installed into /lib/firmware.
      '';
    };

    enableRedistributableFirmware = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to include redistributable firmware for common hardware
        (WiFi, Bluetooth, GPU, etc.). Requires linux-firmware package
        to be available in the package set.
      '';
    };
  };

  config = mkMerge [
    # Auto-add linux-firmware when redistributable firmware is enabled
    (mkIf (cfg.enableRedistributableFirmware && pkgs ? linux-firmware) {
      hardware.firmware = [ pkgs.linux-firmware ];
    })

    # Install combined firmware and set up kernel firmware path
    (mkIf (cfg.firmware != [ ]) {
      system.activationScripts.firmware = stringAfter [ "etc" ] ''
        # Set up firmware path for the kernel
        mkdir -p /lib/firmware
        for fwdir in ${combinedFirmware}/lib/firmware/*; do
          fname=$(basename "$fwdir")
          if [ ! -e "/lib/firmware/$fname" ]; then
            ln -sf "$fwdir" "/lib/firmware/$fname"
          fi
        done

        # Tell the kernel where to find firmware
        if [ -w /sys/module/firmware_class/parameters/path ]; then
          echo "${combinedFirmware}/lib/firmware" > /sys/module/firmware_class/parameters/path
        fi
      '';
    })
  ];
}
