{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  m4,
  xorgproto,
  libxcb,
  xcbutil,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "xcb-util-image";
  version = "0.4.1";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "mirror://xorg/individual/xcb/xcb-util-image-${finalAttrs.version}.tar.xz";
    hash = "sha256-zK2O5drbEnH9RyetFNm9d6ZOUFYIdmxOmCZ9mu3kDT0=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    m4
    pkg-config
  ];

  buildInputs = [
    xorgproto
    libxcb
    xcbutil
  ];

  propagatedBuildInputs = [ libxcb ];

  meta = {
    description = "XCB port of Xlib's XImage and XShmImage functions.";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxcb-image";
    license = lib.licenses.x11;
    pkgConfigModules = [ "xcb-image" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = {
      vendor = "x.org";
      product = "xcb-util-image";
    };
  };
})
