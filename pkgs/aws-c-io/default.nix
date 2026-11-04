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

stdenv.mkDerivation (finalAttrs: {
  pname = "aws-c-io";
  # nixpkgs-update: no auto update
  version = "1.1.1";

  outputs = [
    "out"
    "include"
  ];

  src = fetchFromGitHub {
    owner = "awslabs";
    repo = "aws-c-io";
    tag = "v${finalAttrs.version}";
    hash = "sha256-QqHBqxh+3BP9v4hdxUSt/HwKNPQiTWfpIIqIRCDFdf8=";
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

  cmakeEntries = {
    BUILD_SHARED_LIBS = true;
  };

  passthru.tests = {
    inherit nix;
  };

  meta = {
    description = "AWS SDK for C module for IO and TLS";
    homepage = "https://github.com/awslabs/aws-c-io";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "amazon" finalAttrs.version;
  };
})
