{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  libx11,
  xorgproto,
  libxau,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxext";
  version = "1.3.7";

  outputs = [
    "out"
    "dev"
    "man"
    "doc"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxext";
    tag = "libXext-${finalAttrs.version}";
    hash = "sha256-9Swa4BB8QUKAiSmINeYU5vuIVpJq2Yez0dB4oHTFEEI=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];

  buildInputs = [
    libx11
    xorgproto
  ];
  propagatedBuildInputs = [
    xorgproto
    libxau
  ];

  configureFlags = lib.optional (
    stdenv.hostPlatform != stdenv.buildPlatform
  ) "--enable-malloc0returnsnull";

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "Xlib-based library for common extensions to the X11 protocol";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxext";
    license = with lib.licenses; [
      mitOpenGroup
      x11
      hpnd
      hpndSellVariant
      hpndDocSell
      hpndDoc
      mit
      isc
    ];
    pkgConfigModules = [ "xext" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
