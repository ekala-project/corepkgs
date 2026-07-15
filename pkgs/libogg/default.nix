{
  lib,
  stdenv,
  fetchurl,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libogg";
  version = "1.3.6";

  src = fetchurl {
    url = "https://downloads.xiph.org/releases/ogg/libogg-${finalAttrs.version}.tar.xz";
    hash = "sha256-XIJTQo4YGEDNINQfPKFlV6nMBLrUo9BMzoSAhnf6EGE=";
  };

  outputs = [
    "out"
    "dev"
    "doc"
  ];

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED_LIBS" (!stdenv.hostPlatform.isStatic))
  ];

  meta = {
    description = "Media container library to manipulate Ogg files";
    homepage = "https://xiph.org/ogg/";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.all;
  };
})
