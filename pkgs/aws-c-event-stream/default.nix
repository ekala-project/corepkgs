{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  aws-c-cal,
  aws-c-common,
  aws-c-io,
  aws-checksums,
  nix,
  s2n-tls,
  libexecinfo,
}:

stdenv.mkDerivation rec {
  pname = "aws-c-event-stream";
  version = "0.7.1";

  src = fetchFromGitHub {
    owner = "awslabs";
    repo = "aws-c-event-stream";
    rev = "v${version}";
    hash = "sha256-l0e3KoYk/4nX0QlZ2PlCBzBMXmNrM8x23D5NvEz4SBY=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  buildInputs = [
    aws-c-cal
    aws-c-common
    aws-c-io
    aws-checksums
    s2n-tls
  ]
  ++ lib.optional stdenv.hostPlatform.isMusl libexecinfo;

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS:BOOL=ON"
  ];

  passthru.tests = {
    inherit nix;
  };

  meta = {
    description = "C99 implementation of the vnd.amazon.eventstream content-type";
    homepage = "https://github.com/awslabs/aws-c-event-stream";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
}
