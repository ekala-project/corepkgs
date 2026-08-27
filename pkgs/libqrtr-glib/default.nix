{
  lib,
  stdenv,
  fetchFromGitLab,
  meson,
  mesonEmulatorHook,
  ninja,
  pkg-config,
  gobject-introspection,
  gtk-doc,
  docbook-xsl-nons,
  docbook-xml-dtd,
  glib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libqrtr-glib";
  version = "1.2.2";

  outputs = [
    "out"
    "dev"
    "devdoc"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "mobile-broadband";
    repo = "libqrtr-glib";
    rev = finalAttrs.version;
    sha256 = "kHLrOXN6wgBrHqipo2KfAM5YejS0/bp7ziBSpt0s1i0=";
  };

  strictDeps = true;

  depsBuildBuild = [
    pkg-config
  ];

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
    gobject-introspection
    gtk-doc
    docbook-xsl-nons
    docbook-xml-dtd.v4_3
  ]
  ++ lib.optionals (!stdenv.buildPlatform.canExecute stdenv.hostPlatform) [
    mesonEmulatorHook
  ];

  buildInputs = [
    glib
  ];

  mesonBuildType = "release";

  meta = {
    homepage = "https://gitlab.freedesktop.org/mobile-broadband/libqrtr-glib";
    description = "Qualcomm IPC Router protocol helper library";
    license = lib.licenses.lgpl2Plus;
    platforms = lib.platforms.linux;
  };
})
