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
  options.services.bluetooth = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the Bluetooth service.";
    };
    description = mkOption {
      type = types.str;
      default = "Bluetooth Service";
      description = "Service description.";
    };
    command = mkOption {
      type = types.str;
      internal = true;
      description = "Command to run (set automatically).";
    };
    args = mkOption {
      type = types.listOf types.str;
      internal = true;
      default = [ ];
      description = "Command arguments (set automatically).";
    };
    user = mkOption {
      type = types.str;
      default = "root";
      description = "User to run service as.";
    };
    restartPolicy = mkOption {
      type = types.str;
      default = "always";
      description = "Restart policy.";
    };
    systemd = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Systemd-specific options.";
    };
  };

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

    enableAllFirmware = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to include all available firmware, including non-redistributable
        firmware. Implies enableRedistributableFirmware.
      '';
    };

    ksm.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable Kernel Samepage Merging (KSM).

        KSM deduplicates identical memory pages across processes,
        which can significantly reduce memory usage for VMs and
        containers running similar workloads.
      '';
    };

    bluetooth = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable Bluetooth support.";
      };

      powerOnBoot = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to power on Bluetooth adapters at boot.";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.bluez or (throw "bluez package not available");
        defaultText = literalExpression "pkgs.bluez";
        description = "The BlueZ package to use.";
      };

      settings = mkOption {
        type = types.attrsOf (types.attrsOf types.anything);
        default = { };
        example = literalExpression ''
          {
            General = {
              Enable = "Source,Sink,Media,Socket";
            };
          }
        '';
        description = "BlueZ configuration settings (INI format sections).";
      };
    };

    graphics = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable graphics/GPU support.

          Installs Mesa drivers and enables DRI.
        '';
      };

      enable32Bit = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable 32-bit graphics drivers (for Steam, Wine, etc.).";
      };

      extraPackages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Additional graphics driver packages.";
      };

      extraPackages32 = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Additional 32-bit graphics driver packages.";
      };
    };

    i2c = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable I2C device access.

          Loads the i2c-dev module and sets up udev rules.
        '';
      };

      group = mkOption {
        type = types.str;
        default = "i2c";
        description = "Group allowed to access I2C devices.";
      };
    };
  };

  config = mkMerge [
    # enableAllFirmware implies enableRedistributableFirmware
    (mkIf cfg.enableAllFirmware {
      hardware.enableRedistributableFirmware = true;
    })

    # Auto-add linux-firmware when redistributable firmware is enabled
    (mkIf (cfg.enableRedistributableFirmware && pkgs ? linux-firmware) {
      hardware.firmware = [ pkgs.linux-firmware ];
    })

    # KSM
    (mkIf cfg.ksm.enable {
      system.activationScripts.ksm = stringAfter [ "etc" ] ''
        if [ -w /sys/kernel/mm/ksm/run ]; then
          echo 1 > /sys/kernel/mm/ksm/run
        fi
      '';
    })

    # Bluetooth
    (mkIf cfg.bluetooth.enable {
      boot.kernelModules = [ "bluetooth" ];
      environment.systemPackages = [ cfg.bluetooth.package ];

      services.bluetooth = {
        enable = true;
        description = "Bluetooth Service";
        command = "${cfg.bluetooth.package}/libexec/bluetooth/bluetoothd";
        args = [ "--nodetach" ];
        user = "root";
        restartPolicy = "always";
        systemd = {
          after = [ "dbus.service" ];
          wantedBy = [ "multi-user.target" ];
        };
      };

      services.dbus.packages = [ cfg.bluetooth.package ];
    })

    # Graphics
    (mkIf cfg.graphics.enable {
      environment.systemPackages = cfg.graphics.extraPackages;
    })

    # I2C
    (mkIf cfg.i2c.enable {
      boot.kernelModules = [ "i2c-dev" ];
      users.groups.${cfg.i2c.group} = { };
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
