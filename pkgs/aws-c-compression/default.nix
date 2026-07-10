{
  lib,
  stdenv,
  fetchFromGitHub,
  aws-c-common,
  cmake,
  nix,
}:

stdenv.mkDerivation rec {
  pname = "aws-c-compression";
  version = "0.3.2";

  src = fetchFromGitHub {
    owner = "awslabs";
    repo = "aws-c-compression";
    rev = "v${version}";
    sha256 = "sha256-YckyQZNk+48g5jrT4q8Clmy4LRwswKONvFbVtJxgpYQ=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  buildInputs = [
    aws-c-common
  ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
  ];

  passthru.tests = {
    inherit nix;
  };

  meta = {
    description = "C99 implementation of huffman encoding/decoding";
    homepage = "https://github.com/awslabs/aws-c-compression";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
}
