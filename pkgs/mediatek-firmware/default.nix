{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:

stdenvNoCC.mkDerivation rec {
  pname = "mediatek-firmware";
  version = "20260810";

  src = fetchFromGitLab {
    owner = "kernel-firmware";
    repo = "linux-firmware";
    rev = "refs/tags/${version}";
    hash = "sha256-nG+XL/aetcZMLRhVY7HhmMaOC+/DsgAMKOEbibTk6MQ=";
    sparseCheckout = [ "mediatek" ];
  };

  buildCommand = ''
    mkdir -p $out/lib/firmware
    cp -r $src/mediatek $out/lib/firmware/
  '';

  meta = {
    description = "MediaTek WiFi and Bluetooth firmware from linux-firmware";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
  };
}
