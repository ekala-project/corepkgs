# Adios port of ekaos/modules/hardware/firmware.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{
  types,
  lib,
  pkgs,
  ...
}:

{
  options = {
    # NOTE: the legacy module also declares options.services.bluetooth
    # (flattened below with a `svcBluetooth` prefix to avoid colliding with
    # the hardware.bluetooth leaves).
    svcBluetoothEnable = {
      type = types.bool;
      default = false;
      description = "Whether to enable the Bluetooth service.";
    };

    svcBluetoothDescription = {
      type = types.string;
      default = "Bluetooth Service";
      description = "Service description.";
    };

    svcBluetoothCommand = {
      type = types.string;
      # TODO(adios-cutover): legacy option is internal (set automatically); kept as a plain option.
      description = "Command to run (set automatically).";
    };

    svcBluetoothArgs = {
      type = types.listOf types.string;
      default = [ ];
      # TODO(adios-cutover): legacy option is internal (set automatically); kept as a plain option.
      description = "Command arguments (set automatically).";
    };

    svcBluetoothUser = {
      type = types.string;
      default = "root";
      description = "User to run service as.";
    };

    svcBluetoothRestartPolicy = {
      type = types.string;
      default = "always";
      description = "Restart policy.";
    };

    svcBluetoothSystemd = {
      type = types.attrsOf types.any;
      default = { };
      description = "Systemd-specific options.";
    };

    firmware = {
      type = types.listOf types.derivation;
      default = [ ];
      example = [ pkgs.linux-firmware ];
      description = ''
        List of firmware packages to make available to the kernel.
        These are installed into /lib/firmware.
      '';
    };

    enableRedistributableFirmware = {
      type = types.bool;
      default = false;
      description = ''
        Whether to include redistributable firmware for common hardware
        (WiFi, Bluetooth, GPU, etc.). Requires linux-firmware package
        to be available in the package set.
      '';
    };

    enableAllFirmware = {
      type = types.bool;
      default = false;
      description = ''
        Whether to include all available firmware, including non-redistributable
        firmware. Implies enableRedistributableFirmware.
      '';
    };

    ksmEnable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable Kernel Samepage Merging (KSM).

        KSM deduplicates identical memory pages across processes,
        which can significantly reduce memory usage for VMs and
        containers running similar workloads.
      '';
    };

    bluetoothEnable = {
      type = types.bool;
      default = false;
      description = "Whether to enable Bluetooth support.";
    };

    bluetoothPowerOnBoot = {
      type = types.bool;
      default = true;
      description = "Whether to power on Bluetooth adapters at boot.";
    };

    bluetoothPackage = {
      type = types.derivation;
      default = pkgs.bluez or (throw "bluez package not available");
      description = "The BlueZ package to use.";
    };

    bluetoothSettings = {
      type = types.attrsOf (types.attrsOf types.any);
      default = { };
      example = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
      description = "BlueZ configuration settings (INI format sections).";
    };

    graphicsEnable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable graphics/GPU support.

        Installs Mesa drivers and enables DRI.
      '';
    };

    graphicsEnable32Bit = {
      type = types.bool;
      default = false;
      description = "Whether to enable 32-bit graphics drivers (for Steam, Wine, etc.).";
    };

    graphicsExtraPackages = {
      type = types.listOf types.derivation;
      default = [ ];
      description = "Additional graphics driver packages.";
    };

    graphicsExtraPackages32 = {
      type = types.listOf types.derivation;
      default = [ ];
      description = "Additional 32-bit graphics driver packages.";
    };

    i2cEnable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable I2C device access.

        Loads the i2c-dev module and sets up udev rules.
      '';
    };

    i2cGroup = {
      type = types.string;
      default = "i2c";
      description = "Group allowed to access I2C devices.";
    };
  };

  inputs = {
    facter.from = { parent }: parent.facter;
  };

  impl =
    { options, inputs }:
    let
      # Combine all firmware into a single directory
      combinedFirmware = pkgs.buildEnv {
        name = "firmware";
        paths = options.firmware;
        pathsToLink = [ "/lib/firmware" ];
        ignoreCollisions = true;
      };
    in
    lib.merge.attrs.recursively {
      mutators = [
        # enableAllFirmware implies enableRedistributableFirmware
        (
          if options.enableAllFirmware then
            {
              hardware.enableRedistributableFirmware = true;
            }
          else
            { }
        )

        # When redistributable firmware is enabled without facter, add the
        # combined linux-firmware meta-package as a fallback.  When facter is
        # active, firmware-split.nix selects only the needed sub-packages.
        (
          if (options.enableRedistributableFirmware && !inputs.facter.enable && pkgs ? linux-firmware) then
            {
              hardware.firmware = [ pkgs.linux-firmware ];
            }
          else
            { }
        )

        # KSM
        # TODO(adios-cutover): legacy stringAfter [ "etc" ] ordering lost.
        (
          if options.ksmEnable then
            {
              system.activationScripts.ksm = ''
                if [ -w /sys/kernel/mm/ksm/run ]; then
                  echo 1 > /sys/kernel/mm/ksm/run
                fi
              '';
            }
          else
            { }
        )

        # Bluetooth
        (
          if options.bluetoothEnable then
            {
              boot.kernelModules = [ "bluetooth" ];
              environment.systemPackages = [ options.bluetoothPackage ];

              services.bluetooth = {
                enable = true;
                description = "Bluetooth Service";
                command = "${options.bluetoothPackage}/libexec/bluetooth/bluetoothd";
                args = [ "--nodetach" ];
                user = "root";
                restartPolicy = "always";
                systemd = {
                  after = [ "dbus.service" ];
                  wantedBy = [ "multi-user.target" ];
                };
              };

              services.dbus.packages = [ options.bluetoothPackage ];
            }
          else
            { }
        )

        # Graphics
        (
          if options.graphicsEnable then
            {
              environment.systemPackages = options.graphicsExtraPackages;
            }
          else
            { }
        )

        # I2C
        (
          if options.i2cEnable then
            {
              boot.kernelModules = [ "i2c-dev" ];
              users.groups.${options.i2cGroup} = { };
            }
          else
            { }
        )

        # Install combined firmware and set up kernel firmware path
        # TODO(adios-cutover): legacy stringAfter [ "etc" ] ordering lost.
        (
          if (options.firmware != [ ]) then
            {
              system.activationScripts.firmware = ''
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
            }
          else
            { }
        )
      ];
    };
}
