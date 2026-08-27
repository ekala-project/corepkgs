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
  pname = "libxfixes";
  version = "6.0.2";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxfixes";
    tag = "libXfixes-${finalAttrs.version}";
    hash = "sha256-gMrTjwFLeFK7sRHUv1rFYzNR2sMxODocnL2G+dEOjaU=";
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

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "Xlib-based library for the XFIXES Extension";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxfixes";
    license = with lib.licenses; [
      hpndSellVariant
      mit
    ];
    pkgConfigModules = [ "xfixes" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
