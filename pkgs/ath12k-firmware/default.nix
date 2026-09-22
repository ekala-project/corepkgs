{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:

stdenvNoCC.mkDerivation rec {
  pname = "ath12k-firmware";
  version = "20260810";

  src = fetchFromGitLab {
    owner = "kernel-firmware";
    repo = "linux-firmware";
    rev = "refs/tags/${version}";
    hash = "sha256-rrdYMLF/BvjSfNJXToRPtfu+r6XeCB99SR8nGKJ3ZIo=";
    sparseCheckout = [ "ath12k" ];
  };

  buildCommand = ''
    mkdir -p $out/lib/firmware
    cp -r $src/ath12k $out/lib/firmware/
  '';

  meta = {
    description = "Qualcomm WiFi 7 (ath12k) firmware from linux-firmware";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
  };
}
