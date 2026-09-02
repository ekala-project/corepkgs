{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  gtest,
  runUnitTests,
  withUtils ? false,
  withZlibCompat ? false,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "zlib-ng";
  version = "2.3.3";

  src = fetchFromGitHub {
    owner = "zlib-ng";
    repo = "zlib-ng";
    tag = finalAttrs.version;
    hash = "sha256-6GlHCnx9dQtmViPnvHnMS+l9Z+g6M8ynrSxLhLtmAKU=";
  };

  outputs = [
    "out"
    "dev"
  ]
  ++ lib.optional withUtils "bin";

  strictDeps = true;

  nativeBuildInputs = [
    cmake.minimal
    cmake.configurePhaseHook
    pkg-config
  ];

  env = lib.optionalAttrs stdenv.hostPlatform.isFreeBSD {
    # This can be removed when we switch to libcxx from llvm 20
    # https://github.com/llvm/llvm-project/pull/122361
    NIX_CFLAGS_COMPILE = "-D_XOPEN_SOURCE=700";
  };

  checkInputs = [ gtest ];

  cmakeFlags = [
    "-DCMAKE_INSTALL_PREFIX=/"
    "-DBUILD_SHARED_LIBS=ON"
    # minigzip and minideflate are defined in test/, which CMake only adds when BUILD_TESTING is on
    (lib.cmakeBool "BUILD_TESTING" (withUtils || (finalAttrs.doCheck or false)))
  ]
  ++ lib.optionals withUtils [ "-DINSTALL_UTILS=ON" ]
  ++ lib.optionals withZlibCompat [ "-DZLIB_COMPAT=ON" ];

  passthru.tests.unittests = runUnitTests finalAttrs.finalPackage;

  meta = {
    description = "Zlib data compression library for the next generation systems";
    homepage = "https://github.com/zlib-ng/zlib-ng";
    license = lib.licenses.zlib;
    platforms = lib.platforms.all;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "zlib-ng_project" finalAttrs.version;
  };
})
