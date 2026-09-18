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
  testers,
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

  cmakeEntries = {
    BUILD_SHARED_LIBS = true;
    ENABLE_COMMONCRYPTO = false;
    ENABLE_GNUTLS = false;
    ENABLE_MBEDTLS = false;
    ENABLE_OPENSSL = true;
    ENABLE_WINDOWS_CRYPTO = false;
  };

  passthru.tests = {
    pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    homepage = "https://libzip.org/";
    description = "C library for reading, creating, and modifying zip archives";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
    pkgConfigModules = [ "libzip" ];
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "libzip" finalAttrs.version;
  };
})
