{
  lib,
  stdenv,
  fetchurl,
  gettext,
  meson,
  ninja,
  python3,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "iso-codes";
  version = "4.20.1";

  src = fetchurl {
    url = "https://salsa.debian.org/iso-codes-team/iso-codes/-/archive/v${finalAttrs.version}/iso-codes-v${finalAttrs.version}.tar.gz";
    hash = "sha256-LX2fYISrnObFNM5xo91RRLbkdPPJdhZFmoj3P0SmS/8=";
  };

  postPatch = ''
    patchShebangs scripts
  '';

  nativeBuildInputs = [
    gettext
    meson
    meson.configurePhaseHook
    ninja
    python3
  ];

  meta = {
    homepage = "https://salsa.debian.org/iso-codes-team/iso-codes";
    description = "Various ISO codes packaged as XML files";
    license = lib.licenses.lgpl21;
    platforms = lib.platforms.all;
  };
})
