{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  fontconfig,
  freetype,
  libx11,
  libxrender,
  xorgproto,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxft";
  version = "2.3.9";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxft";
    tag = "libXft-${finalAttrs.version}";
    hash = "sha256-zLPFvLE+OGmaOAxoKVOlKfC9KDYbIvwlpBBhuky5bZ0=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];

  buildInputs = [
    fontconfig
    freetype
    libx11
    libxrender
    xorgproto
  ];

  propagatedBuildInputs = [
    xorgproto
    # header file dependencies
    freetype
    fontconfig
    libxrender
  ];

  configureFlags = lib.optional (
    stdenv.hostPlatform != stdenv.buildPlatform
  ) "--enable-malloc0returnsnull";

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "X FreeType library";
    longDescription = ''
      libxft is the client side font rendering library, using libfreetype, libx11, and the
      X Render extension to display anti-aliased text.
    '';
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxft";
    license = lib.licenses.hpndSellVariant;
    pkgConfigModules = [ "xft" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
