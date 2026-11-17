{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  nasm,
  pkg-config,
  xxhash,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dav1d";
  version = "1.5.5";

  src = fetchFromGitHub {
    owner = "videolan";
    repo = "dav1d";
    tag = finalAttrs.version;
    hash = "sha256-wdqkUWbheDvL815VvZXM+V2MopU4gctLB72vRr8zvNs=";
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
    xxhash
  ];

  mesonEntries = {
    enable_tools = false;
    enable_examples = false;
  };

  doCheck = true;

  meta = {
    description = "Cross-platform AV1 decoder focused on speed and correctness";
    inherit (finalAttrs.src.meta) homepage;
    changelog = "https://code.videolan.org/videolan/dav1d/-/tags/${finalAttrs.version}";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.unix ++ lib.platforms.windows;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "videolan" finalAttrs.version;
  };
})
