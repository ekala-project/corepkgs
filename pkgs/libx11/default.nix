{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  buildPackages,
  pkg-config,
  xorgproto,
  libpthread-stubs,
  libxcb,
  xtrans,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libx11";
  version = "1.8.13";

  outputs = [
    "out"
    "dev"
    "man"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libx11";
    tag = "libX11-${finalAttrs.version}";
    hash = "sha256-9vKn4IB2hiYKwpjzKPR2X8uLxXZLguaLPw2Wq9B7NFE=";
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
    libpthread-stubs
    libxcb
    xtrans
  ];

  propagatedBuildInputs = [
    xorgproto
  ];

  configureFlags =
    lib.optional (stdenv.hostPlatform != stdenv.buildPlatform) "--enable-malloc0returnsnull"
    ++ lib.optional (stdenv.targetPlatform.useLLVM or false) "ac_cv_path_RAWCPP=cpp";

  env = lib.optionalAttrs stdenv.hostPlatform.isDarwin { CPP = "clang -E -"; };

  postInstall = ''
    # Remove useless DocBook XML files.
    rm -r $out/share/doc
  '';

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "Core X11 protocol client library (aka \"Xlib\")";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libx11";
    license = with lib.licenses; [
      mit
      mitOpenGroup
      x11
      hpndDoc
      hpndSellVariant
      tekHvcLicense
      hpndDocSell
      hpnd
      bsd1
      isc
      # The "source code modified by FUJITSU LIMITED under the Joint Development Agreement for the
      # CDE/Motif PST" is possibly unfree.
      # upstream issue: https://gitlab.freedesktop.org/xorg/lib/libx11/-/issues/217
      # unfree
    ];
    pkgConfigModules = [
      "x11"
      "x11-xcb"
    ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
