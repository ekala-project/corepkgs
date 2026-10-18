{
  cmake,
  fetchurl,
  lib,
  libogg,
  pkg-config,
  stdenv,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "flac";
  version = "1.5.0";

  src = fetchurl {
    url = "https://downloads.xiph.org/releases/flac/flac-${finalAttrs.version}.tar.xz";
    hash = "sha256-8sHHZZKoL//4QTujxKEpm2x6sGxzTe4D/YhjBIXCuSA=";
  };

  hardeningDisable = [ "trivialautovarinit" ];

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    pkg-config
  ];

  buildInputs = [ libogg ];

  cmakeEntries = {
    INSTALL_MANPAGES = true;
    BUILD_DOCS = false;
    ${if !stdenv.hostPlatform.isStatic then "BUILD_SHARED_LIBS" else null} = true;
  };

  env = {
    CFLAGS = toString [
      "-O3"
      "-funroll-loops"
    ];
    CXXFLAGS = toString [ "-O3" ];
  };

  patches = [ ./package.patch ];

  outputs = [
    "bin"
    "dev"
    "out"
    "man"
  ];

  meta = {
    homepage = "https://xiph.org/flac/";
    description = "Library and tools for encoding and decoding the FLAC lossless audio file format";
    mainProgram = "flac";
    platforms = lib.platforms.all;
    license = with lib.licenses; [
      bsd3
      fdl13Plus
      gpl2Plus
      lgpl21Plus
    ];
  };
})
