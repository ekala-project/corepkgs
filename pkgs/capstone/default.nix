{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "capstone";
  version = "5.0.7";

  src = fetchFromGitHub {
    owner = "capstone-engine";
    repo = "capstone";
    rev = finalAttrs.version;
    hash = "sha256-+6QReHZK+iIXspizy6Kvk7cj016HOKgiaKSaP4h7mao=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED_LIBS" true)
  ];

  doCheck = true;

  meta = {
    description = "Advanced disassembly library";
    homepage = "http://www.capstone-engine.org";
    license = lib.licenses.bsd3;
    mainProgram = "cstool";
    platforms = lib.platforms.unix;
  };
})
