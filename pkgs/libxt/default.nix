{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  buildPackages,
  pkg-config,
  xorgproto,
  libx11,
  libsm,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxt";
  version = "1.3.1";

  outputDoc = "devdoc";
  outputs = [
    "out"
    "dev"
    "devdoc"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxt";
    tag = "libXt-${finalAttrs.version}";
    hash = "sha256-uwi03NEdDweYDmHijGRc3ARiyvB6X2cypHKGBiKA1sY=";
  };

  strictDeps = true;

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];

  buildInputs = [
    xorgproto
    libx11
    libsm
  ];

  propagatedBuildInputs = [
    xorgproto
    libx11
    # needs to be propagated because of header file dependencies
    libsm
  ];

  configureFlags =
    lib.optional (stdenv.hostPlatform != stdenv.buildPlatform) "--enable-malloc0returnsnull"
    ++ lib.optional (stdenv.targetPlatform.useLLVM or false) "ac_cv_path_RAWCPP=cpp";

  env = {
    CPP = if stdenv.hostPlatform.isDarwin then "clang -E -" else "${stdenv.cc.targetPrefix}cc -E -";
  };

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "X Toolkit Intrinsics library";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxt";
    license = with lib.licenses; [
      mit
      hpndSellVariant
      hpnd
      mitOpenGroup
      x11
    ];
    pkgConfigModules = [ "xt" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
