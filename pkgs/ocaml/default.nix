{
  lib,
  stdenv,
  fetchurl,
  binutils,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "ocaml";
  version = "5.5.0";

  src = fetchurl {
    url = "http://caml.inria.fr/pub/distrib/ocaml-5.5/ocaml-${finalAttrs.version}.tar.xz";
    sha256 = "sha256-/MauZl0exR1SUQ6qx4NKhqmAa/WiWLt8ynhzP8zwFbo=";
  };

  postPatch = lib.optionalString stdenv.cc.isClang ''
    rm testsuite/tests/basic/trigraph.ml
  '';

  strictDeps = true;
  prefixKey = "-prefix ";
  configurePlatforms =
    lib.optionals (!(stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64))
      [
        "host"
        "target"
      ];

  hardeningDisable = lib.optional stdenv.cc.isClang "strictoverflow";

  enableParallelBuilding = true;
  enableParallelInstalling = false;

  makefile = ./Makefile.nixpkgs;
  buildFlags = [ "defaultentry" ];

  depsBuildBuild = lib.optionals (!stdenv.hostPlatform.isDarwin) [ binutils ];

  installTargets = [
    "install"
    "installopt"
  ];

  postBuild = ''
    mkdir -p $out/include
    ln -sv $out/lib/ocaml/caml $out/include/caml
  '';

  passthru = {
    nativeCompilers = true;
  };

  meta = {
    homepage = "https://ocaml.org/";
    license = lib.licenses.lgpl21;
    description = "Industrial-strength programming language supporting functional, imperative and object-oriented styles";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    mainProgram = "ocaml";
  };
})
