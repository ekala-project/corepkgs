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
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxscrnsaver";
  version = "1.2.5";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxscrnsaver";
    tag = "libXScrnSaver-${finalAttrs.version}";
    hash = "sha256-hzLcUGn2bFUWpS7iErlTCuDjrUgT7WIEKQJU/0bAcZ8=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];

  buildInputs = [
    libx11
    libxext
  ];

  propagatedBuildInputs = [ xorgproto ];

  configureFlags = lib.optional (
    stdenv.hostPlatform != stdenv.buildPlatform
  ) "--enable-malloc0returnsnull";

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "X11 Screen Saver extension client library";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxscrnsaver";
    license = lib.licenses.x11;
    pkgConfigModules = [ "xscrnsaver" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
