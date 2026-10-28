{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "catch2";
  version = "3.16.1";

  outputs = [
    "out"
    "include"
  ];

  src = fetchFromGitHub {
    owner = "catchorg";
    repo = "Catch2";
    tag = "v${finalAttrs.version}";
    sha256 = "sha256-T7Wd3Fq2YwjXU7hKm0ej/CIXQtrorPr6qALzfF4UwJU=";
  };

  postPatch = ''
    substituteInPlace CMake/*.pc.in \
      --replace-fail "\''${prefix}/" ""
  '';

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  cmakeFlags = [
    "-H.."
  ];

  cmakeEntries = {
    CMAKE_INSTALL_INCLUDEDIR = "include";
    CMAKE_INSTALL_LIBDIR = "lib";
  };

  meta = {
    description = "Multi-paradigm automated test framework for C++ and Objective-C (and, maybe, C)";
    homepage = "http://catch-lib.net";
    license = lib.licenses.boost;
    platforms = with lib.platforms; unix ++ windows;
  };
})
