{
  lib,
  stdenv,
  fetchFromGitHub,
  perl,
  buildPackages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libstemmer";
  version = "3.1.1";

  src = fetchFromGitHub {
    owner = "snowballstem";
    repo = "snowball";
    tag = "v${finalAttrs.version}";
    sha256 = "sha256-FpvV2brpjl0/l/EmrHN9tWFrXUUz9BDUH548MAjiTa8=";
  };

  nativeBuildInputs = [ perl ];

  prePatch = ''
    patchShebangs .
  ''
  + lib.optionalString (!stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    substituteInPlace GNUmakefile \
      --replace './snowball' '${lib.getBin buildPackages.libstemmer}/bin/snowball'
  '';

  makeTarget = "libstemmer.a";

  installPhase = ''
    install -Dt $out/lib libstemmer.a
    install -Dt $out/include include/libstemmer.h
    install -Dt $out/bin {snowball,stemwords}
  '';

  meta = {
    description = "Snowball Stemming Algorithms";
    homepage = "https://snowballstem.org/";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.all;
  };
})
