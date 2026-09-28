{
  lib,
  stdenv,
  buildPackages,
  fetchurl,
  meson,
  ninja,
  pkg-config,
  fixDarwinDylibNames,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "fribidi";
  version = "1.0.17";

  outputs = [
    "out"
    "dev"
    "devdoc"
  ];

  src = fetchurl {
    url = "https://github.com/fribidi/fribidi/releases/download/v${finalAttrs.version}/fribidi-${finalAttrs.version}.tar.xz";
    sha256 = "sha256-aUnc3ifUHOutH9dB/K/DbVWhAg0thy1KbrORTKq7raI=";
  };

  postPatch = ''
    patchShebangs test
  '';

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
  ]
  ++ lib.optional stdenv.hostPlatform.isDarwin fixDarwinDylibNames;

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  meta = {
    homepage = "https://github.com/fribidi/fribidi";
    description = "GNU implementation of the Unicode Bidirectional Algorithm (bidi)";
    mainProgram = "fribidi";
    license = lib.licenses.lgpl21;
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "fribidi_project" finalAttrs.version;
  };
})
