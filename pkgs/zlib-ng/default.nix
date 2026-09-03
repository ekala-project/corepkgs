{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  gtest,
  runUnitTests,
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
  ];

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
    (lib.cmakeBool "ZLIB_COMPAT" withZlibCompat)
    (lib.cmakeBool "BUILD_SHARED_LIBS" true)
    (lib.cmakeBool "WITH_GTEST" finalAttrs.finalPackage.doCheck)
  ];

  passthru.tests.unittests = runUnitTests finalAttrs.finalPackage;

  meta = {
    description = "Zlib data compression library for the next generation systems";
    homepage = "https://github.com/zlib-ng/zlib-ng";
    license = lib.licenses.zlib;
    platforms = lib.platforms.all;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "zlib-ng_project" finalAttrs.version;
  };
})
