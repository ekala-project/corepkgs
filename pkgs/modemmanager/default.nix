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

  strictDeps = true;

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

  mesonFlags = [
    "-Dudevdir=${placeholder "out"}/lib/udev"
    "-Ddbus_policy_dir=${placeholder "out"}/share/dbus-1/system.d"
    "-Dsystemdsystemunitdir=${placeholder "out"}/lib/systemd/system"
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    (lib.mesonBool "introspection" withIntrospection)
    (lib.mesonBool "qrtr" withIntrospection)
    (lib.mesonBool "vapi" withIntrospection)
    (lib.mesonBool "systemd_suspend_resume" withSystemd)
    (lib.mesonBool "systemd_journal" withSystemd)
    (lib.mesonOption "polkit" (if withPolkit then "strict" else "no"))
  ];

  postPatch = ''
    patchShebangs \
      tools/test-modemmanager-service.py
  '';

  mesonBuildType = "release";

  meta = {
    description = "WWAN modem manager, part of NetworkManager";
    homepage = "https://www.freedesktop.org/wiki/Software/ModemManager/";
    license = lib.licenses.gpl2Plus;
    maintainers = [ ];
    platforms = lib.platforms.linux;
  };
}
