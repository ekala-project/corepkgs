{
  lib,
  stdenv,
  fetchFromGitLab,
  autoreconfHook,
  pkg-config,
  util-macros,
  libfontenc,
  xorgproto,
  freetype,
  xtrans,
  zlib,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxfont_2";
  version = "2.0.9";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxfont";
    tag = "libXfont2-${finalAttrs.version}";
    hash = "sha256-yr3vtS7LCCHGLTns5NwJHExtY25hcYQfVsAiRro5F9w=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
    xtrans
  ];

  buildInputs = [
    libfontenc
    freetype
    xtrans
    zlib
  ];

  propagatedBuildInputs = [ xorgproto ];

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "X font handling library for server & utilities";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxfont";
    license = with lib.licenses; [
      mit
      mitOpenGroup
      hpnd
      hpndSellVariant
    ];
    pkgConfigModules = [ "xfont2" ];
    platforms = lib.platforms.unix;
  };
})
