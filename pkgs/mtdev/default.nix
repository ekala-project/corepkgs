{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "mtdev";
  version = "1.1.7";

  src = fetchurl {
    url = "https://bitmath.org/code/mtdev/mtdev-${finalAttrs.version}.tar.bz2";
    hash = "sha256-oQetrSEB/srFSsf58OCg3RVdlUGT2lXCNAyX8v8dgU4=";
  };

  meta = {
    description = "Multitouch Protocol Translation Library";
    homepage = "https://bitmath.org/code/mtdev/";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
})
