{
  lib,
  stdenv,
  fetchurl,
  meson,
  ninja,
  pkg-config,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libsysprof-capture";
  version = "50.0";

  src = fetchurl {
    url = "mirror://gnome/sources/sysprof/${lib.versions.major finalAttrs.version}/sysprof-${finalAttrs.version}.tar.xz";
    hash = "sha256-qs5E6Q6Q9sNLsvvsjMtHuPgRAwgJeNZXWSh4Q8Mp1To=";
  };

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
  ];

  mesonEntries = {
    sysprofd = "none";
    gtk = false;
    libsysprof = false;
    help = false;
    tools = false;
    tests = false;
    examples = false;
  };

  mesonFeatures = {
    polkit-agent = false;
    debuginfod = false;
  };

  meta = {
    description = "Static library for Sysprof capture data generation";
    homepage = "https://gitlab.gnome.org/GNOME/sysprof";
    license = lib.licenses.bsd2Patent;
    platforms = lib.platforms.all;
    pkgConfigModules = [ "sysprof-capture-4" ];
  };
})
