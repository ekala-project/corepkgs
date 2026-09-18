{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "utf8cpp";
  version = "4.1.1";

  src = fetchFromGitHub {
    owner = "nemtrif";
    repo = "utfcpp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-0NbbQMsucrbOGEWAVZGSFp7f4dp31XrurPVVjcYsH+I=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  cmakeFlags = [
    (lib.cmakeBool "UTF8CPP_ENABLE_TESTS" false)
  ];

  meta = {
    homepage = "https://github.com/nemtrif/utfcpp";
    description = "UTF-8 with C++ in a Portable Way";
    license = lib.licenses.boost;
    platforms = lib.platforms.all;
  };
})
