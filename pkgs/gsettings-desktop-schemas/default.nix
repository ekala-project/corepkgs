{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  glib,
  gobject-introspection,
  buildPackages,
  withIntrospection ?
    lib.meta.availableOn stdenv.hostPlatform gobject-introspection
    && stdenv.hostPlatform.emulatorAvailable buildPackages,
  meson,
  ninja,
}:

stdenv.mkDerivation rec {
  pname = "gsettings-desktop-schemas";
  version = "50.1";

  src = fetchurl {
    url = "mirror://gnome/sources/gsettings-desktop-schemas/${lib.versions.major version}/gsettings-desktop-schemas-${version}.tar.xz";
    hash = "sha256-CiqiUIJnJYXRb82rYcew4z8DX7h0dlBceU8pVlr6SFs=";
  };

  strictDeps = true;
  depsBuildBuild = [ pkg-config ];
  nativeBuildInputs = [
    glib
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
  ]
  ++ lib.optionals withIntrospection [
    gobject-introspection
  ];

  mesonFlags = [
    (lib.mesonBool "introspection" withIntrospection)
  ];

  preInstall = ''
    mkdir -p $out/share/glib-2.0/schemas
    cat - > $out/share/glib-2.0/schemas/remove-backgrounds.gschema.override <<- EOF
      [org.gnome.desktop.background]
      picture-uri='''
      picture-uri-dark='''

      [org.gnome.desktop.screensaver]
      picture-uri='''
    EOF
  '';

  meta = {
    homepage = "https://gitlab.gnome.org/GNOME/gsettings-desktop-schemas";
    description = "Collection of GSettings schemas for settings shared by various components of a desktop";
    license = lib.licenses.lgpl21Plus;
  };
}
