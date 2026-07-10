{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  aws-c-cal,
  aws-c-common,
  nix,
  s2n-tls,
}:

stdenv.mkDerivation rec {
  pname = "aws-c-io";
  # nixpkgs-update: no auto update
  version = "0.27.2";

  src = fetchFromGitHub {
    owner = "awslabs";
    repo = "aws-c-io";
    rev = "v${version}";
    hash = "sha256-0vzuSvJ/4you0YYnizjctKP5AcLm5sJieDOSCHwm1HM=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  buildInputs = [
    aws-c-cal
    aws-c-common
    s2n-tls
  ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
  ];

  # TODO(corepkgs): move to passthru
  doCheck = false;

  passthru.tests = {
    inherit nix;
  };

  meta = {
    description = "AWS SDK for C module for IO and TLS";
    homepage = "https://github.com/awslabs/aws-c-io";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
}
