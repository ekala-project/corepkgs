{
  stdenv,
  lib,
  fetchFromGitHub,
  meson,
  ninja,
  glib,
  pkg-config,
  udev,
  libevdev,
  libgudev,
  python3,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libwacom";
  version = "2.19.1";

  outputs = [
    "bin"
    "out"
    "dev"
  ];

  src = fetchFromGitHub {
    owner = "linuxwacom";
    repo = "libwacom";
    rev = "libwacom-${finalAttrs.version}";
    hash = "sha256-BYfMltOBhb9iS2sTazibcdIaAq5WHecHJIHIfu/cUAQ=";
  };

  postPatch = ''
    patchShebangs test/check-files-in-git.sh
  '';

  nativeBuildInputs = [
    pkg-config
    meson
    meson.configurePhaseHook
    ninja
    python3
  ];

  buildInputs = [
    glib
    udev
    libevdev
    libgudev
  ];

  mesonBuildType = "release";

  mesonFlags = [
    (lib.mesonEnable "tests" false)
    (lib.mesonOption "sysconfdir" "/etc")
  ];

  doInstallCheck = true;

  meta = {
    description = "Libraries, configuration, and diagnostic tools for Wacom tablets running under Linux";
    homepage = "https://linuxwacom.github.io/";
    changelog = "https://github.com/linuxwacom/libwacom/blob/${finalAttrs.src.rev}/NEWS";
    license = lib.licenses.hpnd;
    platforms = lib.platforms.linux;
  };
})
