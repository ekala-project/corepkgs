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
  libxmu,
  libxpm,
  libxt,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxaw";
  version = "1.0.16";

  outputs = [
    "out"
    "dev"
    "devdoc"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxaw";
    tag = "libXaw-${finalAttrs.version}";
    hash = "sha256-aEClL5IvT5Ltn684g08lJrDqtSYOgXzmheUGnNsAVZY=";
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
    libxmu
    libxpm
    libxt
  ];

  propagatedBuildInputs = [
    xorgproto
    libxt
    # needs to be propagated because of header file dependencies
    libxmu
  ];

  postInstall =
    # remove dangling symlinks to .so files on static
    lib.optionalString stdenv.hostPlatform.isStatic "rm $out/lib/*.so*";

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "X Athena Widget Set, based on the X Toolkit Intrinsics (Xt) Library";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxaw";
    license = with lib.licenses; [
      mitOpenGroup
      x11
      hpndSellVariant
      hpnd
    ];
    pkgConfigModules = [
      "xaw6"
      "xaw7"
    ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
