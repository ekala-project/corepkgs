{
  lib,
  stdenv,
  fetchurl,
  cmake,
  pkg-config,
  libGL,
  libGLU,
  libxi,
  libxrandr,
  libxxf86vm,
  libxext,
  libx11,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "freeglut";
  version = "3.6.0";

  src = fetchurl {
    url = "https://github.com/freeglut/freeglut/releases/download/v${finalAttrs.version}/freeglut-${finalAttrs.version}.tar.gz";
    hash = "sha256-nD1NZRb7+gKA7ck8d2mPtzA+RDwaqvN9Jp4yiKbD6lI=";
  };

  outputs = [
    "out"
    "dev"
  ];

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    pkg-config
  ];

  buildInputs = [
    libGL
    libGLU
    libxi
    libxrandr
    libxxf86vm
    libxext
    libx11
  ];

  cmakeBuildType = "Release";

  cmakeFlags = [
    "-DFREEGLUT_BUILD_DEMOS=OFF"
    "-DCMAKE_INSTALL_LIBDIR=lib"
  ];

  meta = {
    description = "Open-source alternative to the OpenGL Utility Toolkit (GLUT) library";
    homepage = "https://freeglut.sourceforge.net/";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
