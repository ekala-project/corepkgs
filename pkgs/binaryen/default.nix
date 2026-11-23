{
  lib,
  stdenv,
  cmake,
  python3,
  fetchFromGitHub,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "binaryen";
  version = "133";

  src = fetchFromGitHub {
    owner = "WebAssembly";
    repo = "binaryen";
    tag = "version_${finalAttrs.version}";
    hash = "sha256-ip10rXDnBfgSLrc4q8TXGckGnyq4SSoXQKoCU/KQIE8=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    python3
  ];

  cmakeEntries = {
    BUILD_TESTS = "0";
  };

  meta = {
    homepage = "https://github.com/WebAssembly/binaryen";
    description = "Compiler infrastructure and toolchain library for WebAssembly, in C++";
    platforms = lib.platforms.all;
    license = lib.licenses.asl20;
  };
})
