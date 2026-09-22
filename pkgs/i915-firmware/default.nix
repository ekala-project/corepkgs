{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:

stdenvNoCC.mkDerivation rec {
  pname = "i915-firmware";
  version = "20260810";

  src = fetchFromGitLab {
    owner = "kernel-firmware";
    repo = "linux-firmware";
    rev = "refs/tags/${version}";
    hash = "sha256-QSGWkqQEcJAVybZSUrbO9o//oJiqZpTSUTEXbpa64Vg=";
    sparseCheckout = [ "i915" ];
  };

  buildCommand = ''
    mkdir -p $out/lib/firmware
    cp -r $src/i915 $out/lib/firmware/
  '';

  meta = {
    description = "Intel GPU (i915) firmware from linux-firmware";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
  };
}
