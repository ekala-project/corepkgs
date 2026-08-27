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
  pname = "xf86-video-chips";
  version = "1.5.0";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "driver";
    repo = "xf86-video-chips";
    tag = "xf86-video-chips-${finalAttrs.version}";
    hash = "sha256-MQ6aT+fWKFtpdzV40LzMrr046h0ZRmHi2sgWjuYUMq8=";
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
    libpciaccess
    xorg-server
  ];
  meta = {
    identifiers.cpeParts.vendor = "x.org";
    description = "Chips & Technologies video driver for the Xorg X server";
    homepage = "https://gitlab.freedesktop.org/xorg/driver/xf86-video-chips";
    license = with lib.licenses; [
      hpndSellVariant
      bsd3
      dec3Clause
      mit
      x11
    ];
    platforms = lib.platforms.unix;
    broken = stdenv.hostPlatform.isAarch64;
  };
})
