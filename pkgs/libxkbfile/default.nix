{
  lib,
  stdenv,
  fetchFromGitLab,
  meson,
  ninja,
  pkg-config,
  xorgproto,
  libx11,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxkbfile";
  version = "1.2.0";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxkbfile";
    tag = "libxkbfile-${finalAttrs.version}";
    hash = "sha256-qOlvaD6s7ogGxMuf6lKgoE60JVcvrM04rl4OxlSKP04=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    xorgproto
    libx11
  ];

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "XKB file handling routines";
    longDescription = ''
      libxkbfile is used by the X servers and utilities to parse the XKB configuration data files.
    '';
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxkbfile";
    license = with lib.licenses; [
      hpnd
      mitOpenGroup
    ];
    pkgConfigModules = [ "xkbfile" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
