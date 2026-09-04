{
  lib,
  stdenv,
  cmake,
  python3,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "binaryen";
  version = "131";

  src = fetchFromGitHub {
    owner = "WebAssembly";
    repo = "binaryen";
    rev = "version_${version}";
    hash = "sha256-7x4I34sWNJIz0X7orJtjU4BQ1CLbIFtkUTqdy5MrxX0=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    python3
  ];

  strictDeps = true;

  preConfigure = ''
    cmakeFlagsArray=($cmakeFlagsArray -DBUILD_TESTS=0)
  '';

  meta = {
    homepage = "https://github.com/WebAssembly/binaryen";
    description = "Compiler infrastructure and toolchain library for WebAssembly, in C++";
    platforms = lib.platforms.all;
    license = lib.licenses.asl20;
  };
}
