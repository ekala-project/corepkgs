{
  lib,
  stdenv,
  fetchurl,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "soxr";
  version = "0.1.3";

  src = fetchurl {
    url = "mirror://sourceforge/soxr/soxr-${finalAttrs.version}-Source.tar.xz";
    sha256 = "12aql6svkplxq5fjycar18863hcq84c5kx8g6f4rj0lcvigw24di";
  };

  outputs = [
    "out"
    "dev"
    "doc"
  ];

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  cmakeFlags = [
    "-DINCLUDE_INSTALL_DIR=${placeholder "dev"}/include"
  ];

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail \
        'cmake_minimum_required (VERSION 3.1 FATAL_ERROR)' \
        'cmake_minimum_required (VERSION 3.10 FATAL_ERROR)'
  '';

  meta = {
    description = "Audio resampling library";
    homepage = "https://soxr.sourceforge.net";
    license = lib.licenses.lgpl21Plus;
    platforms = lib.platforms.unix ++ lib.platforms.windows;
  };
})
