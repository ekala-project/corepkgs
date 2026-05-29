{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "utf8proc";
  version = "2.11.3";

  src = fetchFromGitHub {
    owner = "JuliaStrings";
    repo = "utf8proc";
    tag = "v${finalAttrs.version}";
    hash = "sha256-DF2//R8Oc/+IEJuiG9+rTxQ7nltPcPqdCkzR4T7pUes=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED_LIBS" true)
    (lib.cmakeBool "UTF8PROC_ENABLE_TESTING" false)
  ];

  doCheck = false;

  meta = {
    description = "Clean C library for processing UTF-8 Unicode data";
    homepage = "https://juliastrings.github.io/utf8proc/";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = [ ];
  };
})
