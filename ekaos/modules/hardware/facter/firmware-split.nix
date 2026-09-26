# Adios port of ekaos/modules/hardware/facter/firmware-split.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ pkgs, ... }:

{
  options = { };

  inputs = {
    facter.from = { root }: root.hardware.facter;
    gpu.from = { root }: root.hardware.facter.gpu;
    audio.from = { root }: root.hardware.facter.audio;
  };

  impl =
    { inputs, ... }:
    let
      facterLib = import ./lib.nix { };
      report = inputs.facter.report;

      # Collect all driver modules from network controllers
      networkDrivers = facterLib.collectDrivers (report.hardware.network_controller or [ ]);

      # Collect all driver modules from bluetooth devices
      btDrivers = facterLib.collectDrivers (report.hardware.bluetooth or [ ]);

      # Collect all driver modules from network interfaces (NICs)
      nicDrivers = facterLib.collectDrivers (report.hardware.network_interface or [ ]);

      # Helper: add firmware package if it exists and condition is true
      optionalFirmware = cond: name: if (cond && pkgs ? ${name}) then [ pkgs.${name} ] else [ ];
    in
    if inputs.facter.enable then
      {
        # TODO(adios-cutover): legacy mkAfter ordering lost; nested lists
        # flattened with builtins.concatLists.
        hardware.firmware = builtins.concatLists [
          # GPU firmware
          (optionalFirmware inputs.gpu.amdEnable "amdgpu-firmware")
          (optionalFirmware inputs.gpu.intelEnable "i915-firmware")

          # WiFi firmware (match driver module prefixes on network controllers)
          (optionalFirmware (builtins.any (facterLib.hasPrefix "iwlwifi") networkDrivers) "iwlwifi-firmware")
          (optionalFirmware (builtins.any (facterLib.hasPrefix "ath10k") networkDrivers) "ath10k-firmware")
          (optionalFirmware (builtins.any (facterLib.hasPrefix "ath11k") networkDrivers) "ath11k-firmware")
          (optionalFirmware (builtins.any (facterLib.hasPrefix "ath12k") networkDrivers) "ath12k-firmware")
          (optionalFirmware (builtins.any (facterLib.hasPrefix "rtw88") networkDrivers) "rtw88-firmware")
          (optionalFirmware (builtins.any (facterLib.hasPrefix "rtw89") networkDrivers) "rtw89-firmware")
          (optionalFirmware (builtins.any (facterLib.hasPrefix "brcmfmac") networkDrivers) "brcmfmac-firmware")
          (optionalFirmware (builtins.any (
            m: facterLib.hasPrefix "mt76" m || facterLib.hasPrefix "mt79" m
          ) networkDrivers) "mediatek-firmware")

          # Audio firmware
          (optionalFirmware inputs.audio.sofEnable "intel-sof-firmware")

          # Bluetooth firmware (match driver module prefixes)
          (optionalFirmware (builtins.any (facterLib.hasPrefix "btintel") btDrivers) "intel-bt-firmware")
          (optionalFirmware (builtins.any (facterLib.hasPrefix "btrtl") btDrivers) "realtek-bt-firmware")

          # NIC firmware
          (optionalFirmware (builtins.any (facterLib.hasPrefix "r8169") nicDrivers) "realtek-nic-firmware")
        ];
      }
    else
      { };
}
