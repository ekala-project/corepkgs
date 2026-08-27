{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  libice,
  libuuid,
  xorgproto,
  xtrans,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libsm";
  version = "1.2.6";

  outputs = [
    "out"
    "dev"
    "doc"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libsm";
    tag = "libSM-${finalAttrs.version}";
    hash = "sha256-NbXte3S8DPAblOSUXX0/w3Ex8bSJR+e7AdzPpBNploE=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];

  buildInputs = [
    libice
    libuuid
    xorgproto
    xtrans
  ];

  propagatedBuildInputs = [
    # needs to be propagated because of header file dependencies
    libice
  ];

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "X Session Management Library";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libsm";
    license = with lib.licenses; [
      mit
      mitOpenGroup
    ];
    pkgConfigModules = [ "sm" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
