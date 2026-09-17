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

  mesonFlags = [
    "-Dsysprofd=none"
    "-Dgtk=false"
    "-Dlibsysprof=false"
    "-Dhelp=false"
    "-Dtools=false"
    "-Dtests=false"
    "-Dexamples=false"
    "-Dpolkit-agent=disabled"
    "-Ddebuginfod=disabled"
  ];

  meta = {
    description = "Static library for Sysprof capture data generation";
    homepage = "https://gitlab.gnome.org/GNOME/sysprof";
    license = lib.licenses.bsd2Patent;
    platforms = lib.platforms.all;
    pkgConfigModules = [ "sysprof-capture-4" ];
  };
})
