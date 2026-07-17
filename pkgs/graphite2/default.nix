{
  lib,
  stdenv,
  fetchurl,
  fetchpatch,
  pkg-config,
  freetype,
  cmake,
  static ? stdenv.hostPlatform.isStatic,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "graphite2";
  version = "1.3.14";

  src = fetchurl {
    url = "https://github.com/silnrsi/graphite/releases/download/${finalAttrs.version}/graphite2-${finalAttrs.version}.tgz";
    sha256 = "1790ajyhk0ax8xxamnrk176gc9gvhadzy78qia4rd8jzm89ir7gr";
  };

  outputs = [
    "out"
    "dev"
  ];

  nativeBuildInputs = [
    pkg-config
    cmake.minimal
    cmake.configurePhaseHook
  ];

  buildInputs = [
    freetype
  ];

  patches = [
    (fetchpatch {
      url = "https://src.fedoraproject.org/rpms/graphite2/raw/deba28323b0a3b7a3dcfd06df1efc2195b102ed7/f/graphite2-1.3.14-gcc15.patch";
      hash = "sha256-vkkGkHkcsj1mD3OHCHLWWgpcmFDv8leC4YQm+TsbIUw=";
    })
  ];

  postPatch = ''
    # disable broken 'nametabletest' test
    substituteInPlace tests/CMakeLists.txt \
      --replace 'add_subdirectory(nametabletest)' '#add_subdirectory(nametabletest)'

    # support cross-compilation by using target readelf binary
    substituteInPlace Graphite.cmake \
      --replace 'readelf' "${stdenv.cc.targetPrefix}readelf"

    # headers are located in the dev output
    substituteInPlace CMakeLists.txt \
      --replace-fail ' ''${CMAKE_INSTALL_PREFIX}/include' " ${placeholder "dev"}/include"

    # Fix the build with CMake 4
    badCmakeFiles=(
      CMakeLists.txt
      src/CMakeLists.txt
      tests/{bittwiddling,json,sparsetest,utftest}/CMakeLists.txt
      gr2fonttest/CMakeLists.txt
    )
    for file in "''${badCmakeFiles[@]}"; do
      substituteInPlace "$file" \
        --replace-fail \
          'CMAKE_MINIMUM_REQUIRED(VERSION 2.8.0 FATAL_ERROR)' \
          'CMAKE_MINIMUM_REQUIRED(VERSION 3.10 FATAL_ERROR)'
    done
  '';

  cmakeFlags = lib.optionals static [
    "-DBUILD_SHARED_LIBS=OFF"
  ];

  postConfigure = lib.optionalString static ''
    sed -e '/freetype freetype.c/d' -i ../tests/examples/CMakeLists.txt
  '';

  passthru.tests = {
    pkg-config = testers.hasPkgConfigModules {
      package = finalAttrs.finalPackage;
    };
  };

  meta = {
    description = "Advanced font engine";
    homepage = "https://graphite.sil.org/";
    license = lib.licenses.lgpl21;
    pkgConfigModules = [ "graphite2" ];
    mainProgram = "gr2fonttest";
    platforms = lib.platforms.unix;
    maintainers = [ ];
  };
})
