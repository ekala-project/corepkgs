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
  pname = "xf86-video-cirrus";
  version = "1.6.0";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "driver";
    repo = "xf86-video-cirrus";
    tag = "xf86-video-cirrus-${finalAttrs.version}";
    hash = "sha256-7V3czOujUIKFe9UqNX4FwpDWq9XsZeaLRu9ALnZyRMw=";
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
    description = "Cirrus Logic video driver for the Xorg X server";
    homepage = "https://gitlab.freedesktop.org/xorg/driver/xf86-video-cirrus";
    license = with lib.licenses; [
      x11
      hpndSellVariant
      mit
    ];
    platforms = lib.platforms.unix;
  };
})
