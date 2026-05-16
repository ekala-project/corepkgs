{
  lib,
  stdenv,
  fetchurl,
  cmake,
  zlib,
  bzip2,
  xz,
  zstd,
  openssl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libzip";
  version = "1.11.2";

  src = fetchurl {
    url = "https://libzip.org/download/libzip-${finalAttrs.version}.tar.xz";
    hash = "sha256-XUcTCM70xHUrvPlz2c03uky1NzkRbDA0nUdkuhQQ38E=";
  };

  outputs = [
    "out"
    "dev"
  ];

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  buildInputs = [
    zlib
    bzip2
    xz
    zstd
    openssl
  ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
    "-DENABLE_COMMONCRYPTO=OFF"
    "-DENABLE_GNUTLS=OFF"
    "-DENABLE_MBEDTLS=OFF"
    "-DENABLE_OPENSSL=ON"
    "-DENABLE_WINDOWS_CRYPTO=OFF"
  ];

  enableParallelBuilding = true;

  meta = {
    homepage = "https://libzip.org/";
    description = "C library for reading, creating, and modifying zip archives";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
    pkgConfigModules = [ "libzip" ];
  };
})
