{
  lib,
  stdenv,
  fetchFromGitLab,
  autoreconfHook,
  pkg-config,
  util-macros,
  xorg-server,
  xorgproto,
  libpciaccess,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "xf86-video-vesa";
  version = "2.6.0";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "driver";
    repo = "xf86-video-vesa";
    tag = "xf86-video-vesa-${finalAttrs.version}";
    hash = "sha256-M8/mSgD398wBswOp0oEXvlcgVsYdWcTIw3ah5e1uHV8=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
    xorg-server # for some autoconf macros
  ];

  buildInputs = [
    xorg-server
    xorgproto
    libpciaccess
  ];
  meta = {
    identifiers.cpeParts.vendor = "x.org";
    description = "Generic VESA video driver for the Xorg X server";
    homepage = "https://gitlab.freedesktop.org/xorg/driver/xf86-video-vesa";
    license = lib.licenses.x11;
    platforms = lib.platforms.unix;
    broken = stdenv.hostPlatform.isAarch64;
  };
})
