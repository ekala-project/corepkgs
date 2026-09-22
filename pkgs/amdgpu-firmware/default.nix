{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:

stdenvNoCC.mkDerivation rec {
  pname = "amdgpu-firmware";
  version = "20260810";

  src = fetchFromGitLab {
    owner = "kernel-firmware";
    repo = "linux-firmware";
    rev = "refs/tags/${version}";
    hash = "sha256-SEx3WncWS3VlmUAajH2uS6kWZQ++7YCcVQs4LcXRKs4=";
    sparseCheckout = [ "amdgpu" ];
  };

  buildCommand = ''
    mkdir -p $out/lib/firmware
    cp -r $src/amdgpu $out/lib/firmware/
  '';

  meta = {
    description = "AMD GPU firmware from linux-firmware";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
  };
}
