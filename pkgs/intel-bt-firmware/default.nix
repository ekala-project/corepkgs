{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:

stdenvNoCC.mkDerivation rec {
  pname = "intel-bt-firmware";
  version = "20260810";

  src = fetchFromGitLab {
    owner = "kernel-firmware";
    repo = "linux-firmware";
    rev = "refs/tags/${version}";
    hash = "sha256-VLM3EPAWwzUU62EfrIztyy4WUiYqs016kS/8MJezkKI=";
    sparseCheckout = [ "intel" ];
  };

  buildCommand = ''
    mkdir -p $out/lib/firmware/intel
    cp -r $src/intel/ibt-* $out/lib/firmware/intel/
  '';

  meta = {
    description = "Intel Bluetooth firmware from linux-firmware";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
  };
}
