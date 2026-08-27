{
  lib,
  stdenv,
  fetchFromSourcehut,
  meson,
  ninja,
  pkg-config,
  scdoc,
  systemdLibs,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "seatd";
  version = "0.9.3";

  src = fetchFromSourcehut {
    owner = "~kennylevinsen";
    repo = "seatd";
    rev = finalAttrs.version;
    hash = "sha256-a3L/iFDeFnMGNzC46wXREmSPE+ZX1zUEPnjKPL0bT/A=";
  };

  outputs = [
    "bin"
    "out"
    "dev"
    "man"
  ];

  depsBuildBuild = [
    pkg-config
  ];

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
    scdoc
  ];

  buildInputs = [
    systemdLibs
  ];

  mesonBuildType = "release";

  mesonFlags = [
    "-Dlibseat-logind=systemd"
    "-Dlibseat-builtin=enabled"
    "-Dserver=enabled"
  ];

  meta = {
    description = "Minimal seat management daemon, and a universal seat management library";
    homepage = "https://sr.ht/~kennylevinsen/seatd/";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "seatd";
  };
})
