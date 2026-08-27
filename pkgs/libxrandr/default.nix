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
  libxrender,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxrandr";
  version = "1.5.5";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxrandr";
    tag = "libXrandr-${finalAttrs.version}";
    hash = "sha256-+FtiICqAh539SE60ZZeOzdpKhTxA1M8JxRkwccua8d0=";
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
    libxrender
  ];

  propagatedBuildInputs = [ libxrender ];

  configureFlags = lib.optional (
    stdenv.hostPlatform != stdenv.buildPlatform
  ) "--enable-malloc0returnsnull";

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "Xlib Resize, Rotate and Reflection (RandR) extension library";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxrandr";
    license = lib.licenses.hpndSellVariant;
    pkgConfigModules = [ "xrandr" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
