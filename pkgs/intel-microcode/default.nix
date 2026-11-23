{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "intel-microcode";
  version = "20261110";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "Intel-Linux-Processor-Microcode-Data-Files";
    tag = "microcode-${finalAttrs.version}";
    hash = "sha256-mEf3UwOX1JSb2ELgacj7Wmnm3HYEpFzAlCdgSmsnC7Y=";
  };

  installPhase = ''
    mkdir -p $out/lib/firmware
    cp -r intel-ucode $out/lib/firmware/
  '';

  meta = {
    description = "Intel processor microcode patch";
    homepage = "https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = [ "x86_64-linux" ];
  };
})
