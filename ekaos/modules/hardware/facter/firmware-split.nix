# Auto-select split firmware packages based on detected hardware
{
  lib,
  config,
  pkgs,
  ...
}:
let
  facterLib = import ./lib.nix lib;
  inherit (config.hardware.facter) report;
  cfg = config.hardware.facter.detected;

  # Collect all driver modules from network controllers
  networkDrivers = facterLib.collectDrivers (report.hardware.network_controller or [ ]);

  # Collect all driver modules from bluetooth devices
  btDrivers = facterLib.collectDrivers (report.hardware.bluetooth or [ ]);

  # Collect all driver modules from network interfaces (NICs)
  nicDrivers = facterLib.collectDrivers (report.hardware.network_interface or [ ]);

  # Helper: add firmware package if it exists and condition is true
  optionalFirmware = cond: name: lib.optional (cond && pkgs ? ${name}) pkgs.${name};
in
{
  config = lib.mkIf config.hardware.facter.enable {
    hardware.firmware = lib.mkAfter (
      lib.flatten [
        # GPU firmware
        (optionalFirmware cfg.gpu.amd.enable "amdgpu-firmware")
        (optionalFirmware cfg.gpu.intel.enable "i915-firmware")

        # WiFi firmware (match driver module prefixes on network controllers)
        (optionalFirmware (builtins.any (lib.hasPrefix "iwlwifi") networkDrivers) "iwlwifi-firmware")
        (optionalFirmware (builtins.any (lib.hasPrefix "ath10k") networkDrivers) "ath10k-firmware")
        (optionalFirmware (builtins.any (lib.hasPrefix "ath11k") networkDrivers) "ath11k-firmware")
        (optionalFirmware (builtins.any (lib.hasPrefix "ath12k") networkDrivers) "ath12k-firmware")
        (optionalFirmware (builtins.any (lib.hasPrefix "rtw88") networkDrivers) "rtw88-firmware")
        (optionalFirmware (builtins.any (lib.hasPrefix "rtw89") networkDrivers) "rtw89-firmware")
        (optionalFirmware (builtins.any (lib.hasPrefix "brcmfmac") networkDrivers) "brcmfmac-firmware")
        (optionalFirmware (builtins.any (
          m: lib.hasPrefix "mt76" m || lib.hasPrefix "mt79" m
        ) networkDrivers) "mediatek-firmware")

        # Audio firmware
        (optionalFirmware cfg.audio.sof.enable "intel-sof-firmware")

        # Bluetooth firmware (match driver module prefixes)
        (optionalFirmware (builtins.any (lib.hasPrefix "btintel") btDrivers) "intel-bt-firmware")
        (optionalFirmware (builtins.any (lib.hasPrefix "btrtl") btDrivers) "realtek-bt-firmware")

        # NIC firmware
        (optionalFirmware (builtins.any (lib.hasPrefix "r8169") nicDrivers) "realtek-nic-firmware")
      ]
    );
  };
}
