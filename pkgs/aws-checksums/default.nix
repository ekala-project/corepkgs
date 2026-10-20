{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  aws-c-common,
  nix,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "aws-checksums";
  version = "1.0.1";

  outputs = [
    "out"
    "include"
  ];
  outputInclude = "include";

  src = fetchFromGitHub {
    owner = "awslabs";
    repo = "aws-checksums";
    tag = "v${finalAttrs.version}";
    sha256 = "sha256-QFWr5Kke9cWgxcagoDVptRQeUdUL8VcMysdZFaKiMZE=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  buildInputs = [ aws-c-common ];

  cmakeEntries = {
    BUILD_SHARED_LIBS = true;
  };

  passthru.tests = {
    inherit nix;
  };

  meta = {
    description = "HW accelerated CRC32c and CRC32";
    homepage = "https://github.com/awslabs/aws-checksums";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "amazon" finalAttrs.version;
  };
})
