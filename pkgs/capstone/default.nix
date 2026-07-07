{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  runUnitTests,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "capstone";
  version = "6.0.0-Alpha9";

  src = fetchFromGitHub {
    owner = "capstone-engine";
    repo = "capstone";
    rev = finalAttrs.version;
    hash = "sha256-77RNwlnbjv1EPTdorHSpr8hxVMxdbKPcdCj5jnkgXw4=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED_LIBS" true)
  ];

  passthru.tests.unittests = runUnitTests finalAttrs.finalPackage;

  meta = {
    description = "Advanced disassembly library";
    homepage = "http://www.capstone-engine.org";
    license = lib.licenses.bsd3;
    mainProgram = "cstool";
    platforms = lib.platforms.unix;
  };
})
