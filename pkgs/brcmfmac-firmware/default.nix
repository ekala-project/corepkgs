{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:

stdenvNoCC.mkDerivation rec {
  pname = "brcmfmac-firmware";
  version = "20260810";

  src = fetchFromGitLab {
    owner = "kernel-firmware";
    repo = "linux-firmware";
    rev = "refs/tags/${version}";
    hash = "sha256-E/6Dal8r/lm5VX2ZrnL9BcWgvk3Cnv50iWgrognp204=";
    sparseCheckout = [
      "brcm"
      "cypress"
    ];
  };

  buildCommand = ''
    mkdir -p $out/lib/firmware
    cp -r $src/brcm $out/lib/firmware/
    cp -r $src/cypress $out/lib/firmware/
  '';

  meta = {
    description = "Broadcom/Cypress WiFi and Bluetooth firmware from linux-firmware";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
  };
}
