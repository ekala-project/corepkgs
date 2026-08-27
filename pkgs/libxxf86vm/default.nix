{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  libx11,
  libxext,
  xorgproto,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxxf86vm";
  version = "1.1.7";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxxf86vm";
    tag = "libXxf86vm-${finalAttrs.version}";
    hash = "sha256-6H5gMg93bHgq/gpI7fcamGFh3NJJsA4NpPnUlJSMIzg=";
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
    xorgproto
  ];

  configureFlags = lib.optional (
    stdenv.hostPlatform != stdenv.buildPlatform
  ) "--enable-malloc0returnsnull";

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "Extension library for the XFree86-VidMode X extension";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxxf86vm";
    license = lib.licenses.x11;
    pkgConfigModules = [ "xxf86vm" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
