{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:

stdenvNoCC.mkDerivation rec {
  pname = "iwlwifi-firmware";
  version = "20260810";

  src = fetchFromGitLab {
    owner = "kernel-firmware";
    repo = "linux-firmware";
    rev = "refs/tags/${version}";
    hash = "sha256-TnvvkhVEQNruv375FkchmQQF5ws80s1n9Na67d9l+lg=";
    sparseCheckout = [ "intel/iwlwifi" ];
  };

  buildCommand = ''
    mkdir -p $out/lib/firmware/intel
    cp -r $src/intel/iwlwifi $out/lib/firmware/intel/
  '';

  meta = {
    description = "Intel WiFi (iwlwifi) firmware from linux-firmware";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
  };
}
