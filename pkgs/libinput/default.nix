{
  lib,
  stdenv,
  fetchFromGitLab,
  pkg-config,
  meson,
  ninja,
  libevdev,
  mtdev,
  udev,
  libwacom,
  python3,
  lua5_4,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libinput";
  version = "1.31.3";

  outputs = [
    "bin"
    "out"
    "dev"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "libinput";
    repo = "libinput";
    rev = finalAttrs.version;
    hash = "sha256-2l+YGD1AFTwJRouMg0d3nQX+2me6A4yOB4g2WE2H//g=";
  };

  postPatch = ''
    patchShebangs \
      test/symbols-leak-test \
      test/check-leftover-udev-rules.sh \
      test/helper-copy-and-exec-from-tmp.sh

    # Don't create an empty directory under /etc.
    sed -i "/install_emptydir(dir_etc \/ 'libinput')/d" meson.build
  '';

  nativeBuildInputs = [
    pkg-config
    meson
    meson.configurePhaseHook
    ninja
  ];

  buildInputs = [
    libevdev
    mtdev
    libwacom
    lua5_4
    (python3.withPackages (
      pp: with pp; [
        # TODO(corepkgs): Port python3Packages.libevdev
        # TODO(corepkgs): Port python3Packages.pyudev
        pyyaml
        setuptools
      ]
    ))
    # TODO(corepkgs): Port cairo for event GUI support
    # TODO(corepkgs): Port gtk3 for event GUI support
  ];

  propagatedBuildInputs = [
    udev
  ];

  mesonBuildType = "release";

  mesonFlags = [
    (lib.mesonBool "documentation" false)
    (lib.mesonBool "debug-gui" false)
    (lib.mesonBool "tests" false)
    (lib.mesonBool "libwacom" true)
    (lib.mesonEnable "lua-plugins" true)
    "--sysconfdir=/etc"
    "--libexecdir=${placeholder "bin"}/libexec"
  ];

  doInstallCheck = true;

  meta = {
    description = "Handles input devices in Wayland compositors and provides a generic X.Org input driver";
    mainProgram = "libinput";
    homepage = "https://www.freedesktop.org/wiki/Software/libinput/";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    changelog = "https://gitlab.freedesktop.org/libinput/libinput/-/releases/${finalAttrs.version}";
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "freedesktop" finalAttrs.version;
  };
})
