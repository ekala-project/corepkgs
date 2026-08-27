{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "xtrans";
  version = "1.6.0";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxtrans";
    tag = "xtrans-${finalAttrs.version}";
    hash = "sha256-+V7qrITaYqqC6wFo28jhM3oxpACk1GoEYgK0FRRQJqY=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "X Window System Protocols Transport layer shared code";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxtrans";
    license = with lib.licenses; [
      mitOpenGroup
      hpnd
      mit
      x11
      hpndSellVariant
    ];
    pkgConfigModules = [ "xtrans" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
