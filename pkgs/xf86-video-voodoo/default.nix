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
  pname = "xf86-video-voodoo";
  version = "1.2.6";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "driver";
    repo = "xf86-video-voodoo";
    tag = "xf86-video-voodoo-${finalAttrs.version}";
    hash = "sha256-OuKGgrdGIIUF6CHD1BwO7ZQgvcbhGHQETExv+Ra0X2E=";
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
    description = "Voodoo video driver for the Xorg X server";
    homepage = "https://gitlab.freedesktop.org/xorg/driver/xf86-video-voodoo";
    license = with lib.licenses; [
      # "Relicensed from GPL to the X license by consent of the author"
      x11
      hpndSellVariantSafetyClause
      mit
    ];
    platforms = lib.platforms.unix;
  };
})
