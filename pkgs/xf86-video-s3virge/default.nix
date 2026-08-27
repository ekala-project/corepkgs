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
  pname = "xf86-video-s3virge";
  version = "1.11.1";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "driver";
    repo = "xf86-video-s3virge";
    tag = "xf86-video-s3virge-${finalAttrs.version}";
    hash = "sha256-UxAzsevKIMA3p6Q5cKjRPOku4cfbXiLmcJQWNEjpu7s=";
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
    description = "S3 ViRGE video driver for the Xorg X server";
    homepage = "https://gitlab.freedesktop.org/xorg/driver/xf86-video-s3virge";
    license = with lib.licenses; [
      x11
      free # unknown free license TODO add to spdx
      mit
    ];
    platforms = lib.platforms.unix;
    badPlatforms = lib.platforms.aarch64;
  };
})
