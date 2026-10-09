{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:

stdenvNoCC.mkDerivation rec {
  pname = "intel-sof-firmware";
  version = "20260810";

  src = fetchFromGitLab {
    owner = "kernel-firmware";
    repo = "linux-firmware";
    rev = "refs/tags/${version}";
    hash = "sha256-/D0JvNhGK9i8j1rSCAXJkYjs+5PJL8E0STijT9ZRvng=";
    sparseCheckout = [ "intel" ];
  };

  buildCommand = ''
    mkdir -p $out/lib/firmware/intel
    cp -r $src/intel/dsp_fw_* $out/lib/firmware/intel/
    cp -r $src/intel/fw_sst_* $out/lib/firmware/intel/
  '';

  meta = {
    description = "Intel Sound Open Firmware (SOF) and SST audio firmware from linux-firmware";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
  };
}
