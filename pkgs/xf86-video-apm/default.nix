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
  pname = "xf86-video-apm";
  version = "1.3.0";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "driver";
    repo = "xf86-video-apm";
    tag = "xf86-video-apm-${finalAttrs.version}";
    hash = "sha256-Q10YmtxgWiFvMqvS0RKBhWPVqyFoWNjTe1RLvt7Kxlg=";
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
    description = "Alliance Promotion video driver for the Xorg X server";
    homepage = "https://gitlab.freedesktop.org/xorg/driver/xf86-video-apm";
    license = with lib.licenses; [
      x11
      mit
    ];
    platforms = lib.platforms.unix;
    broken = stdenv.hostPlatform.isAarch64;
  };
})
