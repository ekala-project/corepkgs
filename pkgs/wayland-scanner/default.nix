{
  lib,
  stdenv,
  wayland,
  meson,
  pkg-config,
  ninja,
  wayland-scanner,
  expat,
  libxml2,
  buildPackages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "wayland-scanner";
  inherit (wayland) version src;

  outputs = [
    "out"
    "bin"
    "dev"
  ];

  mesonEntries = {
    documentation = false;
    libraries = false;
    tests = false;
  };

  depsBuildBuild = [ pkg-config ];

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    pkg-config
    ninja
  ]
  ++ lib.optional (stdenv.hostPlatform != stdenv.buildPlatform) wayland-scanner;

  buildInputs = [
    expat
    libxml2
  ];

  meta = {
    inherit (wayland.meta) homepage license;
    mainProgram = "wayland-scanner";
    description = "C code generator for Wayland protocol XML files";
    platforms = lib.platforms.unix;
    pkgConfigModules = [ "wayland-scanner" ];
  };
})
