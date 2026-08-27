{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
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

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxcb-keysyms";
    tag = "xcb-util-keysyms-${finalAttrs.version}";
    hash = "sha256-Dw6b9L8s8yo9VhS5ZqXVm+eeqL9kLemFRQMWag011ss=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];

  buildInputs = [
    libxcb
    xorgproto
  ];

  propagatedBuildInputs = [ libxcb ];

  meta = {
    description = "Standard X key constants and conversion to/from keycodes";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxcb-keysyms";
    license = lib.licenses.x11;
    pkgConfigModules = [ "xcb-keysyms" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = {
      vendor = "x.org";
      product = "xcb-util-keysyms";
    };
  };
})
