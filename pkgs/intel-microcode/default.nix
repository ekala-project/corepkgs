{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation rec {
  pname = "intel-microcode";
  version = "20250512";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "Intel-Linux-Processor-Microcode-Data-Files";
    rev = "microcode-${version}";
    hash = "sha256-xasV1w6+8qnD+RLWsReMo+xm7a9nguV2st3IC4FURDU=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/firmware
    cp -r intel-ucode $out/lib/firmware/
    runHook postInstall
  '';

  meta = {
    description = "Intel processor microcode patch";
    homepage = "https://github.com/intel/Intel-Linux-Processor-Microcode-Data-Files";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = [ "x86_64-linux" ];
  };
}
