{
  lib,
  stdenv,
  fetchFromGitLab,
  autoreconfHook,
  pkg-config,
  util-macros,
  xorgproto,
  libx11,
  libxmu,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "xpr";
  version = "1.2.1";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "app";
    repo = "xpr";
    tag = "xpr-${finalAttrs.version}";
    hash = "sha256-KAWQyVIkqa1zOVNjUAQl4zCqctNwaDLPO+LWE0QoIDk=";
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
    libxmu
  ];

  meta = {
    identifiers.cpeParts.vendor = "x.org";
    description = "Utility to print an X window dump from xwd";
    longDescription = ''
      xpr takes as input a window dump file produced by xwd and formats it for output on various
      types of printers.
    '';
    homepage = "https://gitlab.freedesktop.org/xorg/app/xpr";
    license = with lib.licenses; [
      mit
      x11
      hpnd
    ];
    mainProgram = "xpr";
    platforms = lib.platforms.unix;
  };
})
