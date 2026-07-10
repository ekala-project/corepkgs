{
  lib,
  stdenv,
  fetchFromGitHub,
  aws-c-common,
  cmake,
  nix,
}:

stdenv.mkDerivation rec {
  pname = "aws-c-sdkutils";
  version = "0.2.7";

  src = fetchFromGitHub {
    owner = "awslabs";
    repo = "aws-c-sdkutils";
    rev = "v${version}";
    hash = "sha256-HOnpBQctbWwYtMzXy9CL/OsUrI7nYToRjLuMkXjaifE=";
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

  doCheck = true;

  passthru.tests = {
    inherit nix;
  };

  meta = {
    description = "AWS SDK utility library";
    homepage = "https://github.com/awslabs/aws-c-sdkutils";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
}
