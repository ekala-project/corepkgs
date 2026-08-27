{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  enableShared ? !stdenv.hostPlatform.isStatic,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gflags";
  version = "2.3.0";

  src = fetchFromGitHub {
    owner = "gflags";
    repo = "gflags";
    tag = "v${finalAttrs.version}";
    hash = "sha256-sud3c6XH24YA6vzGQ7LhSoiKycan5JYehC5l2gH6DEo=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  # This isn't used by the build and breaks the CMake build on case-insensitive filesystems (e.g., on Darwin)
  preConfigure = "rm BUILD";

  cmakeBuildType = "Release";

  cmakeFlags = [
    "-DGFLAGS_BUILD_SHARED_LIBS=${if enableShared then "ON" else "OFF"}"
    "-DGFLAGS_BUILD_STATIC_LIBS=ON"
  ];

  meta = {
    description = "C++ library that implements commandline flags processing";
    homepage = "https://gflags.github.io/gflags/";
    changelog = "https://github.com/gflags/gflags/blob/${finalAttrs.src.tag}/ChangeLog.txt";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.linux;
  };
})
