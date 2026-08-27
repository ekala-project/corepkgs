{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  gettext,
  xorgproto,
  libx11,
  libxext,
  libxt,
  ncompress,
  gzip,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxpm";
  version = "3.5.19";

  outputs = [
    "bin"
    "dev"
    "out"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxpm";
    tag = "libXpm-${finalAttrs.version}";
    hash = "sha256-074Fyv6MwJDQZpmhQ1K+J8jQ4xxhOQGmTQgKDHqqQh0=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    gettext
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
    libx11
  ];

  env = {
    XPM_PATH_COMPRESS = lib.makeBinPath [ ncompress ];
    XPM_PATH_GZIP = lib.makeBinPath [ gzip ];
    XPM_PATH_UNCOMPRESS = lib.makeBinPath [ gzip ];
  };

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "X Pixmap (XPM) image file format library";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxpm";
    license = with lib.licenses; [
      x11
      mit
    ];
    mainProgram = "sxpm";
    pkgConfigModules = [ "xpm" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
