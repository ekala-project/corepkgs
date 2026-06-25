{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  libxcb,
  xorgproto,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "xcb-util-keysyms";
  version = "0.4.1";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "mirror://xorg/individual/xcb/xcb-util-keysyms-${finalAttrs.version}.tar.xz";
    hash = "sha256-fCYKUpRBKu1CnfHaL4r9O9B7fLo/7HcvuhWmE6bVxjg=";
  };

  strictDeps = true;

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    libxcb
    xorgproto
  ];

  propagatedBuildInputs = [ libxcb ];

  meta = {
    description = "Standard X key constants and conversion to/from keycodes";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxcb-keysyms";
    license = lib.licenses.x11;
    maintainers = [ ];
    pkgConfigModules = [ "xcb-keysyms" ];
    platforms = lib.platforms.unix;
  };
})
