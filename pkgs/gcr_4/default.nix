{
  pkgs,
  stdenv,
  lib,
  fetchurl,
  pkg-config,
  meson,
  ninja,
  gettext,
  gnupg,
  p11-kit,
  glib,
  libgcrypt,
  libtasn1,
  gtk4,
  pango,
  libsecret,
  openssh,
  systemd,
  gobject-introspection,
  # TODO(corepkgs): wrapGAppsHook4 is not yet available
  # wrapGAppsHook4,
  vala,
  gi-docgen,
  python3,
  shared-mime-info,
  systemdSupport ? lib.meta.availableOn stdenv.hostPlatform systemd,
}:
let
  ini = pkgs.formats.ini { };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "gcr";
  version = "4.4.0.1";

  outputs = [
    "out"
    "bin"
    "dev"
    "devdoc"
  ];

  src = fetchurl {
    url = "mirror://gnome/sources/gcr/${lib.versions.majorMinor finalAttrs.version}/gcr-${finalAttrs.version}.tar.xz";
    hash = "sha256-DDw0Hkn59PJTKkiEUJgEGQoMJmPmEgNguymMXRdKgJg=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
    gettext
    gobject-introspection
    gi-docgen
    # TODO(corepkgs): wrapGAppsHook4 is not yet available
    # wrapGAppsHook4
    vala
    shared-mime-info
  ];

  buildInputs = [
    libgcrypt
    libtasn1
    pango
    libsecret
    openssh
    gtk4
  ]
  ++ lib.optionals systemdSupport [
    systemd
  ];

  propagatedBuildInputs = [
    glib
    p11-kit
  ];

  nativeCheckInputs = [
    python3
  ];

  mesonFlags = [
    "--cross-file=${
      ini.generate "cross-file.conf" {
        binaries = {
          ssh-add = "'${lib.getExe' openssh "ssh-add"}'";
          ssh-agent = "'${lib.getExe' openssh "ssh-agent"}'";
        }
        // lib.optionalAttrs systemdSupport {
          systemctl = "'${lib.getExe' systemd "systemctl"}'";
        };
      }
    }"
  ];

  mesonEntries = {
    gpg_path = "${lib.getBin gnupg}/bin/gpg";
  };

  mesonFeatures = {
    systemd = systemdSupport;
  };

  env.PKG_CONFIG_SYSTEMD_SYSTEMDUSERUNITDIR = "${placeholder "out"}/lib/systemd/user";

  postPatch = ''
    patchShebangs gcr/fixtures/
  '';

  postFixup = ''
    # Cannot be in postInstall, otherwise _multioutDocs hook in preFixup will move right back.
    moveToOutput "share/doc" "$devdoc"
  '';

  meta = {
    description = "GNOME crypto services (daemon and tools)";
    mainProgram = "gcr-viewer-gtk4";
    homepage = "https://gitlab.gnome.org/GNOME/gcr";
    license = lib.licenses.lgpl2Plus;
    platforms = lib.platforms.unix;
    longDescription = ''
      GCR is a library for displaying certificates, and crypto UI, accessing
      key stores. It also provides the viewer for crypto files on the GNOME
      desktop.

      GCK is a library for accessing PKCS#11 modules like smart cards, in a
      (G)object oriented way.
    '';
  };
})
