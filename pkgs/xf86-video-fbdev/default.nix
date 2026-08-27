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
  pname = "xf86-video-fbdev";
  version = "0.5.1";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "driver";
    repo = "xf86-video-fbdev";
    tag = "xf86-video-fbdev-${finalAttrs.version}";
    hash = "sha256-JlSTosvQCiNeWbveYdj4+Ulgd/guc37xYUMaAhyS7K8=";
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
    description = "Framebuffer device video driver for the Xorg X server";
    homepage = "https://gitlab.freedesktop.org/xorg/driver/xf86-video-fbdev";
    license = lib.licenses.x11;
    platforms = lib.platforms.unix;
  };
})
