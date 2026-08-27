{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  libxcb,
  xorgproto,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "xcb-util-renderutil";
  version = "0.3.10";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "mirror://xorg/individual/xcb/xcb-util-renderutil-${finalAttrs.version}.tar.xz";
    hash = "sha256-PhXU8OItjdv7ufXXfbQ+rNejBAKb8lphZsxjyqltBLo=";
  };

  strictDeps = true;

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    libxcb
    xorgproto
  ];

  propagatedBuildInputs = [ libxcb ];

  meta = {
    description = "XCB convenience functions for the Render extension";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxcb-render-util";
    license = with lib.licenses; [
      hpndSellVariant
      x11
    ];
    pkgConfigModules = [ "xcb-renderutil" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = {
      vendor = "x.org";
      product = "xcb-util-renderutil";
    };
  };
})
