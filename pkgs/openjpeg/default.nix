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

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED_LIBS" (!stdenv.hostPlatform.isStatic))
    "-DBUILD_CODEC=ON"
    "-DBUILD_THIRDPARTY=OFF"
    "-DBUILD_JPIP=OFF"
    "-DBUILD_JPIP_SERVER=OFF"
    "-DBUILD_VIEWER=OFF"
    "-DBUILD_JAVA=OFF"
    "-DBUILD_TESTING=OFF"
  ];

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
  };
}
