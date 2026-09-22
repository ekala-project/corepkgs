{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:

stdenvNoCC.mkDerivation rec {
  pname = "ath10k-firmware";
  version = "20260810";

  src = fetchFromGitLab {
    owner = "kernel-firmware";
    repo = "linux-firmware";
    rev = "refs/tags/${version}";
    hash = "sha256-Sp0umsnekew0UaZCT+wd4dwuJO7oe00l2R7eLWyqHTE=";
    sparseCheckout = [ "ath10k" ];
  };

  buildCommand = ''
    mkdir -p $out/lib/firmware
    cp -r $src/ath10k $out/lib/firmware/
  '';

  meta = {
    description = "Qualcomm Atheros 802.11ac (ath10k) firmware from linux-firmware";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
  };
}
