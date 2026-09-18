{
  lib,
  stdenv,
  fetchFromGitLab,
  libglvnd,
  bison,
  flex,
  meson,
  pkg-config,
  ninja,
  python3Packages,
  libdrm,
}:

let
  common = import ./common.nix { inherit lib fetchFromGitLab; };
in
stdenv.mkDerivation rec {
  pname = "mesa-libgbm";

  # We don't use the versions from common.nix, because libgbm is a world rebuild,
  # so the updates need to happen separately on staging.
  version = "25.1.0";

  outputs = [
    "out"
    "include"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "mesa";
    repo = "mesa";
    rev = "mesa-${version}";
    hash = "sha256-UlI+6OMUj5F6uVAw+Mg2wOZrjfdRq73d1qufaXVI/go";
  };

  mesonAutoFeatures = "disabled";

  mesonEntries = {
    gbm-backends-path = "${libglvnd.driverLink}/lib/gbm";

    platforms = "";
    gallium-drivers = "";
    vulkan-drivers = "";
    vulkan-layers = "";
  };

  mesonFeatures = {
    gbm = true;
    egl = false;
    glx = false;
    zlib = false;
  };

  mesonFlags = [
    "--sysconfdir=/etc"
  ];

  propagatedBuildInputs = [ libdrm ];

  nativeBuildInputs = [
    bison
    flex
    meson
    meson.configurePhaseHook
    pkg-config
    ninja
    python3Packages.packaging
    python3Packages.python
    python3Packages.mako
    python3Packages.pyyaml
  ];

  inherit (common) meta;
}
