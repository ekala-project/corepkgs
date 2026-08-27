{
  lib,
  stdenv,
  fetchurl,
  libjpeg,
  libtiff,
  libiconv,
  bash,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "djvulibre";
  version = "3.5.30";

  src = fetchurl {
    url = "mirror://sourceforge/djvu/djvulibre-${finalAttrs.version}.tar.gz";
    hash = "sha256-7l5FfUz+vlZvlLmeXj08x/XHndt0HCrCui5FbwAylkQ=";
  };

  outputs = [
    "bin"
    "out"
    "dev"
    "lib"
    "man"
  ];

  strictDeps = true;

  # TODO(corepkgs): port librsvg, used to rasterise the desktop icons at build time

  buildInputs = [
    libjpeg
    libtiff
    libiconv
    bash
  ];

  enableParallelBuilding = true;

  meta = {
    description = "Big set of CLI tools to make/modify/optimize/show/export DJVU files";
    homepage = "https://djvu.sourceforge.net";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.all;
  };
})
