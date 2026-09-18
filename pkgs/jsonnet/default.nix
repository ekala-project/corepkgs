# jsonnet — Data templating language
{
  stdenv,
  lib,
  cmake,
  fetchFromGitHub,
  gtest,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "jsonnet";
  version = "0.22.0";

  src = fetchFromGitHub {
    rev = "v${finalAttrs.version}";
    owner = "google";
    repo = "jsonnet";
    sha256 = "sha256-3J1Rm5nDgE0casINMoEU7anuuoNmTYmuRorZwKefYSY=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];
  buildInputs = [ gtest ];

  cmakeEntries = {
    USE_SYSTEM_GTEST = true;
    BUILD_STATIC_LIBS = stdenv.hostPlatform.isStatic;
    ${if !stdenv.hostPlatform.isDarwin then "BUILD_SHARED_BINARIES" else null} =
      !stdenv.hostPlatform.isStatic;
  };

  meta = {
    description = "Purely-functional configuration language that helps you define JSON data";
    homepage = "https://github.com/google/jsonnet";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
})
