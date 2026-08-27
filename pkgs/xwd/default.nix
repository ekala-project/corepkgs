{
  lib,
  stdenv,
  fetchFromGitLab,
  autoreconfHook,
  pkg-config,
  util-macros,
  libxkbfile,
  libx11,
  xorgproto,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "xwd";
  version = "1.0.10";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "app";
    repo = "xwd";
    tag = "xwd-${finalAttrs.version}";
    hash = "sha256-F88okvK9OjnYA9WY09vhnFocKLoLUNZTZI2PfhyD98M=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];

  buildInputs = [
    libxkbfile
    libx11
    xorgproto
  ];

  meta = {
    identifiers.cpeParts.vendor = "x.org";
    description = "Utility to dump an image of an X window in XWD format";
    homepage = "https://gitlab.freedesktop.org/xorg/app/xwd";
    license = with lib.licenses; [
      mitOpenGroup
      hpndSellVariant
    ];
    mainProgram = "xwd";
    platforms = lib.platforms.unix;
  };
})
