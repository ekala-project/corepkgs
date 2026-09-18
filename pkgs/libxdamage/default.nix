{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  xorgproto,
  libx11,
  libxfixes,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libxdamage";
  version = "1.1.7";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "mirror://xorg/individual/lib/libXdamage-${finalAttrs.version}.tar.xz";
    hash = "sha256-EnBn9SHT7kZ7l7yxRa66EHjiRU1EjodI65hNWzl73iQ=";
  };

  strictDeps = true;

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    xorgproto
    libx11
    libxfixes
  ];

  propagatedBuildInputs = [ xorgproto ];

  meta = {
    description = "X Damage Extension library";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxdamage";
    license = lib.licenses.hpndSellVariant;
    platforms = lib.platforms.unix;
  };
})
