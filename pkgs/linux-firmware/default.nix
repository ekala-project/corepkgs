{
  lib,
  buildEnv,
  amdgpu-firmware,
  i915-firmware,
  iwlwifi-firmware,
  intel-sof-firmware,
  intel-bt-firmware,
  ath10k-firmware,
  ath11k-firmware,
  ath12k-firmware,
  rtw88-firmware,
  rtw89-firmware,
  brcmfmac-firmware,
  mediatek-firmware,
  realtek-bt-firmware,
  realtek-nic-firmware,
  qcom-firmware,
}:

buildEnv {
  name = "linux-firmware-combined";
  paths = [
    amdgpu-firmware
    i915-firmware
    iwlwifi-firmware
    intel-sof-firmware
    intel-bt-firmware
    ath10k-firmware
    ath11k-firmware
    ath12k-firmware
    rtw88-firmware
    rtw89-firmware
    brcmfmac-firmware
    mediatek-firmware
    realtek-bt-firmware
    realtek-nic-firmware
    qcom-firmware
  ];
  pathsToLink = [ "/lib/firmware" ];
  ignoreCollisions = true;

  meta = {
    description = "Linux firmware blobs (combined meta-package)";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
  };
}
