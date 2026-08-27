{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  xorgproto,
  zlib,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libfontenc";
  version = "1.1.9";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libfontenc";
    tag = "libfontenc-${finalAttrs.version}";
    hash = "sha256-upChhVST27M5h2KKCcb5bN5MZrgIxgDthrwHH96ZNwc=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];

  buildInputs = [
    xorgproto
    zlib
  ];

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "X font encoding library";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libfontenc";
    license = lib.licenses.mit;
    pkgConfigModules = [ "fontenc" ];
    platforms = lib.platforms.unix;
  };
})
