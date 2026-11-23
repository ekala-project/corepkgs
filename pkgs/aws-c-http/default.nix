{
  lib,
  stdenv,
  fetchFromGitHub,
  aws-c-cal,
  aws-c-common,
  aws-c-compression,
  aws-c-io,
  cmake,
  nix,
  s2n-tls,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "aws-c-http";
  # nixpkgs-update: no auto update
  version = "1.3.1";

  outputs = [
    "out"
    "include"
  ];

  src = fetchFromGitHub {
    owner = "awslabs";
    repo = "aws-c-http";
    tag = "v${finalAttrs.version}";
    hash = "sha256-7fPU/bld3LBsEGkmzIbVJvO9bIai8KNz/GhCPGla1zo=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  buildInputs = [
    aws-c-cal
    aws-c-common
    aws-c-compression
    aws-c-io
    s2n-tls
  ];

  cmakeEntries = {
    BUILD_SHARED_LIBS = true;
  };

  passthru.tests = {
    inherit nix;
  };

  meta = {
    description = "C99 implementation of the HTTP/1.1 and HTTP/2 specifications";
    homepage = "https://github.com/awslabs/aws-c-http";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "amazon" finalAttrs.version;
  };
})
