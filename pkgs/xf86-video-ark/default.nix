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
  pname = "xf86-video-ark";
  version = "0.7.6";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "driver";
    repo = "xf86-video-ark";
    tag = "xf86-video-ark-${finalAttrs.version}";
    hash = "sha256-IE35hEZVsfxjwrNxV/xtw8bdox9pwlO/Ra8vkcK19pM=";
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
    description = "ARK Logic video driver for the Xorg X server";
    homepage = "https://gitlab.freedesktop.org/xorg/driver/xf86-video-ark";
    license = lib.licenses.hpndSellVariant;
    platforms = lib.platforms.unix;
    badPlatforms = lib.platforms.aarch64;
  };
})
