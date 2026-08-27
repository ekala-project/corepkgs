{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
  testers,
  autoreconfHook,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "util-macros";
  version = "1.20.2";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "util";
    repo = "macros";
    tag = "util-macros-${finalAttrs.version}";
    hash = "sha256-COIWe7GMfbk76/QUIRsN5yvjd6MEarI0j0M+Xa0WoKQ=";
  };

  strictDeps = true;

  nativeBuildInputs = [ autoreconfHook ];

  passthru.tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;

  meta = {
    description = "GNU autoconf macros shared across X.Org projects";
    homepage = "https://gitlab.freedesktop.org/xorg/util/macros";
    license =
      with lib.licenses;
      AND [
        hpndSellVariant
        mit
      ];
    pkgConfigModules = [ "xorg-macros" ];
    platforms = lib.platforms.unix;
  };
})
