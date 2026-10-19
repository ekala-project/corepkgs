{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "intel-microcode";
  version = "20250512";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "Intel-Linux-Processor-Microcode-Data-Files";
    tag = "microcode-${finalAttrs.version}";
    hash = "sha256-xasV1w6+8qnD+RLWsReMo+xm7a9nguV2st3IC4FURDU=";
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
