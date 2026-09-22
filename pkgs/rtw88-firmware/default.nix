{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:

stdenvNoCC.mkDerivation rec {
  pname = "rtw88-firmware";
  version = "20260810";

  src = fetchFromGitLab {
    owner = "kernel-firmware";
    repo = "linux-firmware";
    rev = "refs/tags/${version}";
    hash = "sha256-blsfOcBrtD5eEvEWBWQEo3I+Ffj7r39R03ul3zgXssM=";
    sparseCheckout = [ "rtw88" ];
  };

  buildCommand = ''
    mkdir -p $out/lib/firmware
    cp -r $src/rtw88 $out/lib/firmware/
  '';

  meta = {
    description = "Realtek WiFi (rtw88) firmware from linux-firmware";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
  };
}
