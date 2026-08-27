{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  xorgproto,
  libx11,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxrender";
  version = "0.9.12";

  outputs = [
    "out"
    "dev"
    "doc"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxrender";
    tag = "libXrender-${finalAttrs.version}";
    hash = "sha256-zgzPpJYq6VCN3uLfvP7BzULxAopaSjsx3zJDTLz0E3c=";
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
  ];

  propagatedBuildInputs = [
    xorgproto
    libx11
  ];

  configureFlags = lib.optional (
    stdenv.hostPlatform != stdenv.buildPlatform
  ) "--enable-malloc0returnsnull";

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "Xlib library for the Render Extension to the X11 protocol";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxrender";
    license = lib.licenses.hpndSellVariant;
    pkgConfigModules = [ "xrender" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
