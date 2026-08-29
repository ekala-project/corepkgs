{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  xorgproto,
  libx11,
  libxfixes,
  libxrender,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxcursor";
  version = "1.2.3";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxcursor";
    tag = "libXcursor-${finalAttrs.version}";
    hash = "sha256-PjeYzxgg1eu0JHeS+tznMXkrz5Fm1IQxlpa4qKWU9ws=";
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
    libxfixes
    libxrender
  ];

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "X11 Cursor management library";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxcursor";
    license = lib.licenses.hpndSellVariant;
    pkgConfigModules = [ "xcursor" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
