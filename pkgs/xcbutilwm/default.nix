{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  libxcb,
  xorgproto,
  m4,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "xcb-util-wm";
  version = "0.4.2";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "mirror://xorg/individual/xcb/xcb-util-wm-${finalAttrs.version}.tar.xz";
    hash = "sha256-YsNOIdBiZGh/rqftv2NjLJ8E1V5yEUqkpXu5Xk+Iigs=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
    m4
  ];

  buildInputs = [
    libxcb
    xorgproto
  ];

  propagatedBuildInputs = [ libxcb ];

  meta = {
    description = "XCB client and window-manager helpers for ICCCM & EWMH.";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxcb-wm";
    license = lib.licenses.x11;
    pkgConfigModules = [
      "xcb-ewmh"
      "xcb-icccm"
    ];
    platforms = lib.platforms.unix;
  };
})
