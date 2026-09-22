{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:

stdenvNoCC.mkDerivation rec {
  pname = "realtek-nic-firmware";
  version = "20260810";

  src = fetchFromGitLab {
    owner = "kernel-firmware";
    repo = "linux-firmware";
    rev = "refs/tags/${version}";
    hash = "sha256-+s3vcjaby1y2H5bhY02WlmafXdgExtO5zQEpHoGZlz4=";
    sparseCheckout = [ "rtl_nic" ];
  };

  buildCommand = ''
    mkdir -p $out/lib/firmware
    cp -r $src/rtl_nic $out/lib/firmware/
  '';

  meta = {
    description = "Realtek NIC firmware from linux-firmware";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
  };
}
