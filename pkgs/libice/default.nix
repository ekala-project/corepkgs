{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  xorgproto,
  xtrans,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libice";
  version = "1.1.2";

  outputs = [
    "out"
    "dev"
    "doc"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libice";
    tag = "libICE-${finalAttrs.version}";
    hash = "sha256-AYldp7v3x2Um0Ln75E06544l1ftTzR6m5gGenuLkp6U=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];

  buildInputs = [
    xorgproto
    xtrans
  ];

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "Inter-Client Exchange Library";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libice";
    license = lib.licenses.mitOpenGroup;
    pkgConfigModules = [ "ice" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
