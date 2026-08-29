{
  lib,
  stdenv,
  fetchFromGitLab,
  font-util,
  util-macros,
  autoreconfHook,
  pkg-config,
  libxfont_2,
  xorgproto,
  xtrans,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "xfs";
  version = "1.2.2";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "app";
    repo = "xfs";
    tag = "xfs-${finalAttrs.version}";
    hash = "sha256-t9x40XKkwUj2YxxHi4LIHqIZeiF6VDgmXiD4aaSg9c8=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    font-util
    pkg-config
    util-macros
    xtrans
  ];

  buildInputs = [
    libxfont_2
    xorgproto
    xtrans
  ];

  meta = {
    identifiers.cpeParts.vendor = "x.org";
    description = "X Font Server, for X11 core protocol fonts";
    homepage = "https://gitlab.freedesktop.org/xorg/app/xfs";
    license = with lib.licenses; [
      mitOpenGroup
      hpndSellVariant
      x11
      hpnd
    ];
    mainProgram = "xfs";
    platforms = lib.platforms.unix;
    broken = stdenv.hostPlatform.isStatic;
  };
})
