{
  lib,
  stdenv,
  fetchurl,
  meson,
  ninja,
  pkg-config,
  gobject-introspection,
  buildPackages,
  withDconf ? !stdenv.hostPlatform.isDarwin && lib.meta.availableOn stdenv.hostPlatform dconf,
  withIntrospection ?
    lib.meta.availableOn stdenv.hostPlatform gobject-introspection
    && stdenv.hostPlatform.emulatorAvailable buildPackages,
  gsettings-desktop-schemas,
  makeWrapper,
  python3,
  dbus,
  glib,
  dconf,
  libx11,
  libxml2,
  libxtst,
  libxi,
  libxext,
  systemdLibs,
  systemdSupport ? lib.meta.availableOn stdenv.hostPlatform systemdLibs,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "at-spi2-core";
  version = "2.60.6";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "mirror://gnome/sources/at-spi2-core/${lib.versions.majorMinor finalAttrs.version}/at-spi2-core-${finalAttrs.version}.tar.xz";
    hash = "sha256-qJtkqLIXqAQr3w41y/q2Kc7uNWQNunXfV4r96ap4nVc=";
  };

  nativeBuildInputs = [
    glib
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
    makeWrapper
    python3
  ]
  ++ lib.optionals withIntrospection [
    gobject-introspection
  ];

  buildInputs = [
    libx11
    libxml2
    libxtst
    libxi
    libxext
  ]
  ++ lib.optionals systemdSupport [
    systemdLibs
  ];

  propagatedBuildInputs = [
    dbus
    glib
  ];

  mesonFlags = [
    "-Ddbus_daemon=dbus-daemon"
  ]
  ++ lib.optionals systemdSupport [
    "-Ddbus_broker=dbus-broker-launch"
  ]
  ++ lib.optionals (!systemdSupport) [
    "-Duse_systemd=false"
  ]
  ++ lib.optionals (!withIntrospection) [
    (lib.mesonEnable "introspection" false)
  ];

  postFixup = ''
    busLauncherWrapperArgs=(
      --prefix PATH : "/run/current-system/sw/bin:/usr/bin"
      ${lib.optionalString withDconf ''--prefix GIO_EXTRA_MODULES : "${lib.getLib dconf}/lib/gio/modules"''}
      --prefix XDG_DATA_DIRS : ${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}
    )
    wrapProgram "$out/libexec/at-spi-bus-launcher" "''${busLauncherWrapperArgs[@]}"
  '';

  meta = {
    description = "Assistive Technology Service Provider Interface protocol definitions and daemon for D-Bus";
    homepage = "https://gitlab.gnome.org/GNOME/at-spi2-core";
    license = lib.licenses.lgpl21Plus;
    platforms = lib.platforms.unix;
  };
})
