{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  xorgproto,
  libx11,
  libxext,
  libxt,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxmu";
  version = "1.3.1";

  outputs = [
    "out"
    "dev"
    "doc"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxmu";
    tag = "libXmu-${finalAttrs.version}";
    hash = "sha256-D6a9GDvlayUtG/lhNmHeQz9tY13y8QOcQBz8sBeSs6o=";
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
    libxt
  ];

  propagatedBuildInputs = [
    xorgproto
    libx11
    libxt
  ];

  buildFlags = [ "BITMAP_DEFINES='-DBITMAPDIR=\"/no-such-path\"'" ];

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "X miscellaneous utility routines library";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxmu";
    license = with lib.licenses; [
      mitOpenGroup
      hpnd
      x11
      isc
    ];
    pkgConfigModules = [
      "xmu"
      "xmuu"
    ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
