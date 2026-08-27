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
  pname = "libxinerama";
  version = "1.1.6";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxinerama";
    tag = "libXinerama-${finalAttrs.version}";
    hash = "sha256-QeodBViEMwXLqWewArNVXQo/a9mU/2eGUnqdHbWMTNE=";
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
  ];

  propagatedBuildInputs = [ xorgproto ];

  configureFlags = lib.optional (
    stdenv.hostPlatform != stdenv.buildPlatform
  ) "--enable-malloc0returnsnull";

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "Library for Xinerama extension to X11 Protocol";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxinerama";
    license = with lib.licenses; [
      mit
      mitOpenGroup
      x11NoPermitPersons
    ];
    pkgConfigModules = [ "xinerama" ];
    platforms = lib.platforms.unix;
  };
})
