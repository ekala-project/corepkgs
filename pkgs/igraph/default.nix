{
  stdenv,
  lib,
  fetchFromGitHub,
  bison,
  blas,
  cmake,
  flex,
  gmp,
  lapack,
  libxml2,
  libxslt,
  llvmPackages,
  pkg-config,
  python3,
}:

assert (blas.isILP64 == lapack.isILP64 && !blas.isILP64);

stdenv.mkDerivation (finalAttrs: {
  pname = "igraph";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "igraph";
    repo = "igraph";
    tag = finalAttrs.version;
    hash = "sha256-mXaW9UOTPN5iM7ZNoV2NjH+2Maez5A/YfABeQRe0vgY=";
  };

  postPatch = ''
    echo "${finalAttrs.version}" > IGRAPH_VERSION
  '';

  outputs = [
    "out"
    "dev"
  ];

  nativeBuildInputs = [
    bison
    cmake
    cmake.configurePhaseHook
    flex
    libxml2
    libxslt
    pkg-config
    python3
  ];

  buildInputs = [
    blas
    gmp
    lapack
    libxml2
  ]
  ++ lib.optionals stdenv.cc.isClang [ llvmPackages.openmp ];

  cmakeEntries = {
    IGRAPH_USE_INTERNAL_BLAS = false;
    IGRAPH_USE_INTERNAL_LAPACK = false;
    IGRAPH_USE_INTERNAL_ARPACK = true;
    IGRAPH_USE_INTERNAL_GLPK = true;
    IGRAPH_USE_INTERNAL_GMP = false;
    IGRAPH_USE_INTERNAL_PLFIT = true;
    IGRAPH_GLPK_SUPPORT = true;
    IGRAPH_GRAPHML_SUPPORT = true;
    IGRAPH_OPENMP_SUPPORT = true;
    IGRAPH_ENABLE_LTO = "AUTO";
    IGRAPH_ENABLE_TLS = true;
    BUILD_SHARED_LIBS = true;
  };

  postFixup = ''
    substituteInPlace $dev/lib/cmake/igraph/igraph-targets.cmake \
      --replace-fail "_IMPORT_PREFIX \"$out\"" "_IMPORT_PREFIX \"$dev\""
  ''
  + lib.optionalString stdenv.hostPlatform.isDarwin ''
    install_name_tool -change libblas.dylib ${blas}/lib/libblas.dylib $out/lib/libigraph.dylib
  '';

  meta = {
    description = "C library for complex network analysis and graph theory";
    homepage = "https://igraph.org/";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.all;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "igraph" finalAttrs.version;
  };
})
