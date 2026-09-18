{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  libpng,
  zlib,
}:

stdenv.mkDerivation rec {
  pname = "openjpeg";
  version = "2.5.4";

  src = fetchFromGitHub {
    owner = "uclouvain";
    repo = "openjpeg";
    rev = "v${version}";
    hash = "sha256-HSXGdpHUbwlYy5a+zKpcLo2d+b507Qf5nsaMghVBlZ8=";
  };

  outputs = [
    "out"
    "dev"
  ];

  cmakeEntries = {
    BUILD_SHARED_LIBS = !stdenv.hostPlatform.isStatic;
    BUILD_CODEC = true;
    BUILD_THIRDPARTY = false;
    BUILD_JPIP = false;
    BUILD_JPIP_SERVER = false;
    BUILD_VIEWER = false;
    BUILD_JAVA = false;
    BUILD_TESTING = false;
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    pkg-config
  ];

  buildInputs = [
    libpng
    zlib
  ];

  passthru = {
    incDir = "openjpeg-${lib.versions.majorMinor version}";
  };

  meta = {
    description = "Open-source JPEG 2000 codec written in C language";
    homepage = "https://www.openjpeg.org/";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.all;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "uclouvain" version;
  };
}
