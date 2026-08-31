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
  libxfixes,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxi";
  version = "1.8.3";

  outputs = [
    "out"
    "dev"
    "doc"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxi";
    tag = "libXi-${finalAttrs.version}";
    hash = "sha256-7MCExKNeBWKKJwpWut+gUKj/Y1UnEE5ZWpefkYYkfv4=";
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
    libxfixes
  ];

  propagatedBuildInputs = [
    xorgproto
    # header file dependencies
    libx11
    libxext
    libxfixes
  ];

  configureFlags =
    lib.optional (stdenv.hostPlatform != stdenv.buildPlatform) "xorg_cv_malloc0_returns_null=no"
    ++ lib.optional stdenv.hostPlatform.isStatic "--disable-shared";

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "library for the X Input Extension";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxi";
    license = with lib.licenses; [
      mitOpenGroup
      hpnd
      mit
    ];
    pkgConfigModules = [ "xi" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
