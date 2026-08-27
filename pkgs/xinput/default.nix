{
  lib,
  stdenv,
  fetchFromGitLab,
  autoreconfHook,
  pkg-config,
  util-macros,
  xorgproto,
  libx11,
  libxext,
  libxi,
  libxinerama,
  libxrandr,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "xinput";
  version = "1.6.4";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "app";
    repo = "xinput";
    tag = "xinput-${finalAttrs.version}";
    hash = "sha256-EsSytLzwAHMwseW4pD/c+/J1MaCWPsE7RPoMIwT96yk=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];

  buildInputs = [
    xorgproto
    libx11
    libxext
    libxi
    libxinerama
    libxrandr
  ];

  meta = {
    identifiers.cpeParts.vendor = "x.org";
    description = "Utility to configure and test XInput devices";
    homepage = "https://gitlab.freedesktop.org/xorg/app/xinput";
    license = with lib.licenses; [
      hpndSellVariant
      mit
    ];
    mainProgram = "xinput";
    platforms = lib.platforms.unix;
  };
})
