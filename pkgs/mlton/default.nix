# MLton — Standard ML compiler (binary bootstrap)
{
  lib,
  stdenv,
  fetchurl,
  gmp,
}:

let
  dynamic-linker = stdenv.cc.bintools.dynamicLinker;
in

stdenv.mkDerivation rec {
  pname = "mlton";
  version = "20241230";

  src =
    if stdenv.hostPlatform.system == "x86_64-linux" then
      (fetchurl {
        url = "https://github.com/MLton/mlton/releases/download/on-${version}-release/${pname}-${version}-1.amd64-linux.ubuntu-24.04_glibc2.39.tgz";
        hash = "sha256-ldXnjHcWGu77LP9WL6vTC6FngzhxPFAUflAA+bpIFZM=";
      })
    else if stdenv.hostPlatform.system == "aarch64-linux" then
      (fetchurl {
        url = "https://github.com/MLton/mlton/releases/download/on-${version}-release/${pname}-${version}-1.arm64-linux.ubuntu-24.04-arm_glibc2.39.tgz";
        hash = "sha256-rn65t253SfUShAM3kXiLQJHT7JS7EO3fAPB23LWIwfc=";
      })
    else
      throw "MLton: unsupported platform ${stdenv.hostPlatform.system}";

  buildInputs = [ gmp ];
  strictDeps = true;

  buildPhase = ''
    make update \
      CC="$(type -p cc)" \
      WITH_GMP_INC_DIR="${gmp.dev}/include" \
      WITH_GMP_LIB_DIR="${gmp}/lib"
  '';

  installPhase = ''
    make install PREFIX=$out
  '';

  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    patchelf --set-interpreter ${dynamic-linker} $out/lib/mlton/mlton-compile
    patchelf --set-rpath ${gmp}/lib $out/lib/mlton/mlton-compile

    for e in mllex mlnlffigen mlprof mlyacc; do
      patchelf --set-interpreter ${dynamic-linker} $out/bin/$e
      patchelf --set-rpath ${gmp}/lib $out/bin/$e
    done
  '';

  meta = {
    description = "Open-source, whole-program, optimizing Standard ML compiler";
    homepage = "http://mlton.org/";
    license = lib.licenses.smlnj;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
