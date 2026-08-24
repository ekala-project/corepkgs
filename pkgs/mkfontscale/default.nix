{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  libfontenc,
  freetype,
  xorgproto,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "mkfontscale";
  version = "1.2.4";

  src = fetchurl {
    url = "mirror://xorg/individual/app/mkfontscale-${finalAttrs.version}.tar.xz";
    hash = "sha256-oBSSoXqbbA7j+S7leIUOMFMVufKY2l8AahzUtR2wGl4=";
  };

  strictDeps = true;
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    libfontenc
    freetype
    xorgproto
    zlib
  ];

  meta = {
    description = "Utilities to create the fonts.scale and fonts.dir index files used by the legacy X11 font system";
    homepage = "https://gitlab.freedesktop.org/xorg/app/mkfontscale";
    license = with lib.licenses; [
      mit
      mitOpenGroup
      hpndSellVariant
    ];
    maintainers = [ ];
    mainProgram = "mkfontscale";
    platforms = lib.platforms.unix;
  };
})
