{
  lib,
  stdenv,
  fetchFromGitHub,
  libaom,
  cmake,
  pkg-config,
  zlib,
  libpng,
  libjpeg,
  libwebp,
  dav1d,
  libyuv,
}:

stdenv.mkDerivation rec {
  pname = "libavif";
  version = "1.4.2";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitHub {
    owner = "AOMediaCodec";
    repo = "libavif";
    rev = "v${version}";
    hash = "sha256-AMQ1TRPGpuBBW7tJ8xuLEVTAeOsLWTHuE0dFJjI7+W4=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    pkg-config
  ];

  buildInputs = [
    zlib
    libpng
    libjpeg
    libwebp
  ];

  propagatedBuildInputs = [
    dav1d
    libaom
    libyuv
  ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
    "-DAVIF_CODEC_AOM=SYSTEM"
    "-DAVIF_CODEC_DAV1D=SYSTEM"
    "-DAVIF_BUILD_APPS=OFF"
    "-DAVIF_BUILD_GDK_PIXBUF=OFF"
    "-DAVIF_LIBYUV=SYSTEM"
  ];

  meta = {
    description = "C implementation of the AV1 Image File Format";
    homepage = "https://github.com/AOMediaCodec/libavif";
    license = lib.licenses.bsd2;
    maintainers = [ ];
    platforms = lib.platforms.unix;
  };
}
