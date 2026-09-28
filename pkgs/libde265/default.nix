{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,

  callPackage,

  # for passthru.tests
  imagemagick,
  libheif,
  gstreamer,
}:

stdenv.mkDerivation (finalAttrs: {
  version = "1.1.3";
  pname = "libde265";

  outputs = [
    "out"
    "include"
  ];
  outputInclude = "include";

  src = fetchFromGitHub {
    owner = "strukturag";
    repo = "libde265";
    tag = "v${finalAttrs.version}";
    hash = "sha256-3bU0xevUSCkyzQUed9PS9p5hXb689Hr9acCAdeWfk0g=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    pkg-config
  ];

  passthru.tests = {
    inherit imagemagick libheif;
    gst-plugins-bad = gstreamer.plugins-bad;

    test-corpus-decode = callPackage ./test-corpus-decode.nix {
      libde265 = finalAttrs.finalPackage;
    };
  };

  meta = {
    homepage = "https://github.com/strukturag/libde265";
    changelog = "https://github.com/strukturag/libde265/releases/tag/${finalAttrs.src.tag}";
    description = "Open h.265 video codec implementation";
    mainProgram = "dec265";
    license = lib.licenses.lgpl3;
    platforms = lib.platforms.unix;
  };
})
