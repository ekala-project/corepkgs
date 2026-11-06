{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "mtools";
  version = "4.0.50";

  src = fetchurl {
    url = "mirror://gnu/mtools/mtools-${finalAttrs.version}.tar.bz2";
    hash = "sha256-86WObPwmNLA8JARCVI47ABA2kjV6/Cjh5xBHRN1keLU=";
  };

  enableParallelBuilding = true;

  meta = {
    homepage = "https://www.gnu.org/software/mtools/";
    description = "Utilities to access MS-DOS disks";
    platforms = lib.platforms.unix;
    license = lib.licenses.gpl3;
  };
})
