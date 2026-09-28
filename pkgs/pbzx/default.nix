{
  stdenv,
  lib,
  fetchFromGitHub,
  xz,
  xar,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pbzx";
  version = "1.1.0";
  src = fetchFromGitHub {
    owner = "NiklasRosenstein";
    repo = "pbzx";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-chc6Yk/EYUlYEE8VETYKMpAl+cyaYEJ9Pd+iyIdtjS8=";
  };
  buildInputs = [
    xz
    xar
  ];
  buildPhase = ''
    ${stdenv.cc.targetPrefix}cc pbzx.c -llzma -lxar -o pbzx
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp pbzx $out/bin
  '';
  meta = {
    description = "Stream parser of Apple's pbzx compression format";
    homepage = "https://github.com/NiklasRosenstein/pbzx";
    platforms = lib.platforms.unix;
    license = lib.licenses.gpl3;

    mainProgram = "pbzx";
  };
})
