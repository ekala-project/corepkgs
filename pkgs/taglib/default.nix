{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  utf8cpp,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "taglib";
  version = "2.3.2";

  src = fetchFromGitHub {
    owner = "taglib";
    repo = "taglib";
    rev = "v${finalAttrs.version}";
    hash = "sha256-8q7goHzzAfiqjy+l1gtSVhiLIuwzbcKa3qywtnj1f9s=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  buildInputs = [
    zlib
    utf8cpp
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED_LIBS" (!stdenv.hostPlatform.isStatic))
  ];

  meta = {
    homepage = "https://taglib.org/";
    description = "Library for reading and editing audio file metadata";
    license = with lib.licenses; [
      lgpl21Only
      mpl11
    ];
    platforms = lib.platforms.all;
  };
})
