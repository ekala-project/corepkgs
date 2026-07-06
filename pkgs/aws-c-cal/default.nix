{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  aws-c-common,
  nix,
  openssl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "aws-c-cal";
  # nixpkgs-update: no auto update
  version = "0.9.14";

  src = fetchFromGitHub {
    owner = "awslabs";
    repo = "aws-c-cal";
    rev = "v${finalAttrs.version}";
    hash = "sha256-eKTi/1DFjIiOqMZ2ekUxvedKsS7n9YnkI7zaia/7CMo=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  buildInputs = [
    aws-c-common
    openssl
  ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
  ];

  passthru.tests = {
    inherit nix;
  };

  meta = {
    description = "AWS Crypto Abstraction Layer";
    homepage = "https://github.com/awslabs/aws-c-cal";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
})
