# Adios port of ekaos/modules/installer/hardware-profile.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
#
# Legacy is a config-only module (no options of its own); it becomes an
# impl-only adios module.
{ pkgs, ... }:

{
  options = { };

  impl = { ... }: {
    # ── Firmware ──────────────────────────────────────────────────────
    hardware.enableRedistributableFirmware = true;

    # ── GPU ───────────────────────────────────────────────────────────
    boot.initrd.kernelModules = [
      # Intel
      "i915"
      # AMD
      "amdgpu"
      # NVIDIA (nouveau for live boot — proprietary needs post-install opt-in)
      "nouveau"
    ];

    # TODO(adios-cutover): priority lost (was mkDefault).
    hardware.graphics.enable = true;

    # ── Audio + network + input + thunderbolt + camera ────────────────
    boot.initrd.availableKernelModules = [
      # Intel HDA (most desktops and older laptops)
      "snd_hda_intel"
      # Intel SOF (Tiger Lake+ laptops)
      "snd_sof_pci"
      "snd_sof_pci_intel_tgl"
      "snd_sof_pci_intel_mtl"
      "snd_sof_intel_hda_common"
      # AMD audio
      "snd_hda_codec_realtek"
      "snd_hda_codec_hdmi"
      # USB audio
      "snd_usb_audio"

      # ── Network ─────────────────────────────────────────────────────
      # Intel Ethernet
      "e1000e"
      "igc"
      "igb"
      "ixgbe"
      # Realtek Ethernet
      "r8169"
      # Broadcom
      "tg3"
      # Intel WiFi
      "iwlwifi"
      # Qualcomm/Atheros WiFi
      "ath11k_pci"
      "ath10k_pci"
      # Realtek WiFi
      "rtw89_8852be"
      "rtw88_8822ce"
      # MediaTek WiFi
      "mt7921e"
      # Broadcom WiFi
      "brcmfmac"

      # ── Input ───────────────────────────────────────────────────────
      "hid_generic"
      "hid_multitouch"
      "i2c_hid_acpi"
      "i2c_hid"

      # ── Thunderbolt ─────────────────────────────────────────────────
      "thunderbolt"

      # ── Camera (IPU6/IPU7 raw kernel support) ───────────────────────
      "intel_ipu6"
      "intel_ipu6_isys"
    ];

    # ── Bluetooth ─────────────────────────────────────────────────────
    # TODO(adios-cutover): priority lost (was mkDefault).
    hardware.bluetooth.enable = true;

    # ── Gamepad / controller modules (hot-plug) ───────────────────────
    boot.kernelModules = [
      "xpad"
      "hid-sony"
      "hid-nintendo"
    ];

    # ── nixos-facter for post-install hardware detection ──────────────
    environment.systemPackages = [
      pkgs.nixos-facter
    ];
  };
}
