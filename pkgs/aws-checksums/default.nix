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
  version = "0.2.7";

  src = fetchFromGitHub {
    owner = "awslabs";
    repo = "aws-checksums";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-dYDTDWZJJ0JlvkMfLS376uUt5QzSmbV0UNRC4aq35TY=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  buildInputs = [ aws-c-common ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
  ];

  doCheck = false;

  passthru.tests = {
    inherit nix;
    unit = finalAttrs.finalPackage.overrideAttrs { doCheck = true; };
  };

  meta = {
    description = "HW accelerated CRC32c and CRC32";
    homepage = "https://github.com/awslabs/aws-checksums";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
})
