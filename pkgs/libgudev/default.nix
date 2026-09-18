{
  stdenv,
  lib,
  fetchurl,
  pkg-config,
  meson,
  ninja,
  udev,
  glib,
  vala,
  gobject-introspection,
  buildPackages,
  withIntrospection ?
    lib.meta.availableOn stdenv.hostPlatform gobject-introspection
    && stdenv.hostPlatform.emulatorAvailable buildPackages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libgudev";
  version = "238";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "mirror://gnome/sources/libgudev/${lib.versions.majorMinor finalAttrs.version}/libgudev-${finalAttrs.version}.tar.xz";
    hash = "sha256-YSZqsa/J1z28YKiyr3PpnS/f9H2ZVE0IV2Dk+mZ7XdE=";
  };

  nativeBuildInputs = [
    pkg-config
    meson
    meson.configurePhaseHook
    ninja
    glib
  ]
  ++ lib.optionals withIntrospection [
    gobject-introspection
    vala
  ];

  buildInputs = [
    udev
    glib
  ];

  mesonFeatures = {
    introspection = withIntrospection;
    vapi = withIntrospection;
    tests = false;
  };

  meta = {
    description = "Library that provides GObject bindings for libudev";
    homepage = "https://gitlab.gnome.org/GNOME/libgudev";
    license = lib.licenses.lgpl2Plus;
    platforms = lib.platforms.linux;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "gnome" finalAttrs.version;
  };
})
