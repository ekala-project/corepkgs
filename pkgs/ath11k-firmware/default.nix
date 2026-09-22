{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:

stdenvNoCC.mkDerivation rec {
  pname = "ath11k-firmware";
  version = "20260810";

  src = fetchFromGitLab {
    owner = "kernel-firmware";
    repo = "linux-firmware";
    rev = "refs/tags/${version}";
    hash = "sha256-QEfill7hIbSSGreee4LYJPr/xSwU1s2uACJWd4YoO+s=";
    sparseCheckout = [ "ath11k" ];
  };

  buildCommand = ''
    mkdir -p $out/lib/firmware
    cp -r $src/ath11k $out/lib/firmware/
  '';

  meta = {
    description = "Qualcomm Atheros 802.11ax (ath11k) firmware from linux-firmware";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
  };
}
