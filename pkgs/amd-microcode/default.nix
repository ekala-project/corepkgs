{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:

stdenvNoCC.mkDerivation rec {
  pname = "amd-microcode";
  version = "20260810";

  src = fetchFromGitLab {
    owner = "kernel-firmware";
    repo = "linux-firmware";
    rev = "refs/tags/${version}";
    hash = "sha256-NguR9l9fwUWUB3iWa5s/BlwNBxdPBfc/6mylUHrnFe8=";
    sparseCheckout = [ "amd-ucode" ];
  };

  buildCommand = ''
    mkdir -p $out/lib/firmware
    cp -r $src/amd-ucode $out/lib/firmware/
  '';

  meta = {
    description = "AMD processor microcode patch";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = [ "x86_64-linux" ];
  };
}
