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
  version = "1.17.0";

  src = fetchurl {
    url = "https://github.com/ngtcp2/nghttp3/releases/download/v${finalAttrs.version}/nghttp3-${finalAttrs.version}.tar.bz2";
    hash = "sha256-KobUa0Kx37XGLk/sO/5ugO5JVxXhiAqEaFdyiBDJgm0=";
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

  cmakeFlags = [
    (lib.cmakeBool "ENABLE_SHARED_LIB" (!stdenv.hostPlatform.isStatic))
    (lib.cmakeBool "ENABLE_STATIC_LIB" stdenv.hostPlatform.isStatic)
  ];

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
  };
})
