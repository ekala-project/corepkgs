{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:

stdenvNoCC.mkDerivation rec {
  pname = "realtek-bt-firmware";
  version = "20260810";

  src = fetchFromGitLab {
    owner = "kernel-firmware";
    repo = "linux-firmware";
    rev = "refs/tags/${version}";
    hash = "sha256-MdGveTZwoTfXnuN6HFxFZqScegALY/keSS3l0/UGQ3k=";
    sparseCheckout = [ "rtl_bt" ];
  };

  buildCommand = ''
    mkdir -p $out/lib/firmware
    cp -r $src/rtl_bt $out/lib/firmware/
  '';

  meta = {
    description = "Realtek Bluetooth firmware from linux-firmware";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
  };
}
