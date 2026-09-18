{
  lib,
  stdenv,
  fetchFromGitLab,
  glib,
  libgudev,
  ppp,
  gettext,
  pkg-config,
  libxslt,
  python3,
  libmbim,
  libqmi,
  bash-completion,
  meson,
  ninja,
  vala,
  dbus,
  bash,
  gobject-introspection,
  udevCheckHook,
  buildPackages,
  withIntrospection ?
    lib.meta.availableOn stdenv.hostPlatform gobject-introspection
    && stdenv.hostPlatform.emulatorAvailable buildPackages,
  polkit,
  withPolkit ? lib.meta.availableOn stdenv.hostPlatform polkit,
  systemd,
  withSystemd ? lib.meta.availableOn stdenv.hostPlatform systemd,
}:

stdenv.mkDerivation rec {
  pname = "modemmanager";
  version = "1.24.2";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "mobile-broadband";
    repo = "ModemManager";
    rev = version;
    hash = "sha256-rBLOqpx7Y2BB6/xvhIw+rDEXsLtePhHLBvfpSuJzQik=";
  };

  patches = [
    ./no-dummy-dirs-in-sysconfdir.patch
  ];

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    gettext
    glib
    pkg-config
    libxslt
    python3
    udevCheckHook
  ]
  ++ lib.optionals withIntrospection [
    gobject-introspection
    vala
  ];

  buildInputs = [
    glib
    libgudev
    ppp
    libmbim
    libqmi
    bash-completion
    dbus
    bash
  ]
  ++ lib.optionals withPolkit [
    polkit
  ]
  ++ lib.optionals withSystemd [
    systemd
  ];

  mesonEntries = {
    udevdir = "${placeholder "out"}/lib/udev";
    dbus_policy_dir = "${placeholder "out"}/share/dbus-1/system.d";
    systemdsystemunitdir = "${placeholder "out"}/lib/systemd/system";
    introspection = withIntrospection;
    qrtr = withIntrospection;
    vapi = withIntrospection;
    systemd_suspend_resume = withSystemd;
    systemd_journal = withSystemd;
    polkit = if withPolkit then "strict" else "no";
  };

  mesonFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
  ];

  postPatch = ''
    patchShebangs \
      tools/test-modemmanager-service.py
  '';

  meta = {
    description = "WWAN modem manager, part of NetworkManager";
    homepage = "https://www.freedesktop.org/wiki/Software/ModemManager/";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "freedesktop" version;
  };
}
