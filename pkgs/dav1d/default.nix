{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  nasm,
  pkg-config,
  xxHash,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dav1d";
  version = "1.5.3";

  src = fetchFromGitHub {
    owner = "videolan";
    repo = "dav1d";
    rev = finalAttrs.version;
    hash = "sha256-E3da/LJ8HNy1osExmupovqnL8JHgVNzPUCG5F8TJKXQ=";
  };

  outputs = [
    "out"
    "dev"
  ];

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    nasm
    pkg-config
  ];

  buildInputs = [
    xxHash
  ];

  mesonFlags = [
    "-Denable_tools=false"
    "-Denable_examples=false"
  ];

  doCheck = true;

  meta = {
    description = "Cross-platform AV1 decoder focused on speed and correctness";
    inherit (finalAttrs.src.meta) homepage;
    changelog = "https://code.videolan.org/videolan/dav1d/-/tags/${finalAttrs.version}";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.unix ++ lib.platforms.windows;
  };
})
