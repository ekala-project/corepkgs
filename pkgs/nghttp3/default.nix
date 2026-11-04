{
  lib,
  stdenv,
  fetchurl,
  cmake,
  curl,
  runUnitTests,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "nghttp3";
  version = "1.19.0";

  src = fetchurl {
    url = "https://github.com/ngtcp2/nghttp3/releases/download/v${finalAttrs.version}/nghttp3-${finalAttrs.version}.tar.bz2";
    hash = "sha256-4RVyQwioub5Ooe7kmoZH9vJicbZh+r9Y2BQ78UII4LI=";
  };

  outputs = [
    "out"
    "dev"
    "doc"
  ];

  nativeBuildInputs = [
    cmake.minimal
    cmake.configurePhaseHook
  ];

  cmakeEntries = {
    ENABLE_SHARED_LIB = !stdenv.hostPlatform.isStatic;
    ENABLE_STATIC_LIB = stdenv.hostPlatform.isStatic;
  };

  passthru.tests = {
    unittests = runUnitTests finalAttrs.finalPackage;
    inherit curl;
  };

  meta = {
    homepage = "https://github.com/ngtcp2/nghttp3";
    changelog = "https://github.com/ngtcp2/nghttp3/releases/tag/v${finalAttrs.version}";
    description = "Implementation of HTTP/3 mapping over QUIC and QPACK in C";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "nghttp2" finalAttrs.version;
  };
})
