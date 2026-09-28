# lobster — Lobster programming language
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  libGL,
  libxcursor,
  libxext,
  libxi,
  libx11,
  libxrandr,
  libxscrnsaver,
  libxtst,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lobster";
  version = "2026.8";

  src = fetchFromGitHub {
    owner = "aardappel";
    repo = "lobster";
    tag = "v${finalAttrs.version}";
    hash = "sha256-OC4LF0z84GzUT92G8dGyxgKJwWeV03XbZcepFhbwZII=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    pkg-config
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    libGL
    libxcursor
    libx11
    libxext
    libxi
    libxrandr
    libxscrnsaver
    libxtst
  ];

  preConfigure = ''
    cd dev
  '';

  meta = {
    description = "Lobster programming language";
    homepage = "https://strlen.com/lobster/";
    license = lib.licenses.asl20;
    mainProgram = "lobster";
    platforms = lib.platforms.all;
  };
})
