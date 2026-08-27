{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
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

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxcb-image";
    tag = "xcb-util-image-${finalAttrs.version}";
    hash = "sha256-k6+wSHKnWSkZK6gm2lYCsnTRz43OLMdO8iVRoEhtRwQ=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    m4
    pkg-config
    util-macros
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
