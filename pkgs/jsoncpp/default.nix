{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  python3,
  validatePkgConfig,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "jsoncpp";
  version = "1.9.7";

  strictDeps = true;

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitHub {
    owner = "open-source-parsers";
    repo = "jsoncpp";
    rev = finalAttrs.version;
    hash = "sha256-rf8d2UNTVEZhuiyChK2XnUbfGDvsfXnKADhaSp8qBwQ=";
  };

  # During darwin bootstrap, cp may not understand --reflink=auto
  unpackPhase = ''
    cp -a ${finalAttrs.src} ${finalAttrs.src.name}
    chmod -R +w ${finalAttrs.src.name}
    export sourceRoot=${finalAttrs.src.name}
  '';

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    python3
    validatePkgConfig
  ];

  cmakeEntries = {
    BUILD_SHARED_LIBS = true;
    BUILD_OBJECT_LIBS = false;
    JSONCPP_WITH_CMAKE_PACKAGE = true;
    BUILD_STATIC_LIBS = false;
    ${if stdenv.buildPlatform != stdenv.hostPlatform then "JSONCPP_WITH_TESTS" else null} = false;
  };

  meta = {
    homepage = "https://github.com/open-source-parsers/jsoncpp";
    description = "C++ library for interacting with JSON";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
