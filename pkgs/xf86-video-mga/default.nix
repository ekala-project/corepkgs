{
  lib,
  stdenv,
  fetchFromGitLab,
  autoreconfHook,
  pkg-config,
  util-macros,
  xorg-server,
  xorgproto,
  libdrm,
  libpciaccess,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "xf86-video-mga";
  version = "2.1.0";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "driver";
    repo = "xf86-video-mga";
    tag = "xf86-video-mga-${finalAttrs.version}";
    hash = "sha256-9DpqSyGTu4jOttZlF95/rpi2oEu+JPU3sniuHTatoRo=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
    xorg-server # for some autoconf macros
  ];

  buildInputs = [
    xorgproto
    libdrm
    libpciaccess
    xorg-server
  ];
  meta = {
    identifiers.cpeParts.vendor = "x.org";
    description = "Matrox video driver for the Xorg X server";
    homepage = "https://gitlab.freedesktop.org/xorg/driver/xf86-video-mga";
    license = with lib.licenses; [
      x11
      mitOpenGroup
      hpndSellVariant
      mit
    ];
    platforms = lib.platforms.unix;
  };
})
