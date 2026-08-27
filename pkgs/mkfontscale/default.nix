{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  libfontenc,
  freetype,
  xorgproto,
  zlib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "mkfontscale";
  version = "1.2.4";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "app";
    repo = "mkfontscale";
    tag = "mkfontscale-${finalAttrs.version}";
    hash = "sha256-R5IB2KuQzp4hRZtGkRdHvf3kSpFLDvLdOVB77Pld7rc=";
  };

  strictDeps = true;
  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];
  buildInputs = [
    libfontenc
    freetype
    xorgproto
    zlib
  ];

  meta = {
    description = "Utilities to create the fonts.scale and fonts.dir index files used by the legacy X11 font system";
    homepage = "https://gitlab.freedesktop.org/xorg/app/mkfontscale";
    license = with lib.licenses; [
      mit
      mitOpenGroup
      hpndSellVariant
    ];
    mainProgram = "mkfontscale";
    platforms = lib.platforms.unix;
  };
})
