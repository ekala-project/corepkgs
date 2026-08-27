{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  autoreconfHook,
  gettext,
  glib,
  buildPackages,
}:

stdenv.mkDerivation rec {
  pname = "gts";
  version = "0.7.6";

  outputs = [
    "bin"
    "dev"
    "out"
  ];

  src = fetchurl {
    url = "mirror://sourceforge/gts/gts-${version}.tar.gz";
    sha256 = "07mqx09jxh8cv9753y2d2jsv7wp8vjmrd7zcfpbrddz3wc9kx705";
  };

  nativeBuildInputs = [
    pkg-config
    autoreconfHook
    glib
  ];
  buildInputs = [ gettext ];
  propagatedBuildInputs = [ glib ];

  env.NIX_CFLAGS_COMPILE = "-std=gnu17";

  preBuild = lib.optionalString (stdenv.hostPlatform != stdenv.buildPlatform) ''
    pushd src
    make CC=${buildPackages.stdenv.cc}/bin/cc predicates_init
    mv predicates_init predicates_init_build
    make clean
    popd
    substituteInPlace src/Makefile --replace "./predicates_init" "./predicates_init_build"
  '';

  meta = {
    homepage = "https://gts.sourceforge.net/";
    license = lib.licenses.lgpl2Plus;
    description = "GNU Triangulated Surface Library";
    platforms = lib.platforms.unix;
  };
}
