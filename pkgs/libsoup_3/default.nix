{
  stdenv,
  lib,
  fetchurl,
  glib,
  meson,
  ninja,
  pkg-config,
  sqlite,
  buildPackages,
  gobject-introspection,
  withIntrospection ?
    lib.meta.availableOn stdenv.hostPlatform gobject-introspection
    && stdenv.hostPlatform.emulatorAvailable buildPackages,
  vala,
  libpsl,
  python3,
  gi-docgen,
  brotli,
  libnghttp2,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libsoup";
  version = "3.6.6";

  outputs = [
    "out"
    "dev"
  ]
  ++ lib.optional withIntrospection "devdoc";

  src = fetchurl {
    url = "mirror://gnome/sources/${finalAttrs.pname}/${lib.versions.majorMinor finalAttrs.version}/${finalAttrs.pname}-${finalAttrs.version}.tar.xz";
    hash = "sha256-Ue0K4G+dWkD0Af9Fni5fZS+aUQt3MOE1nuZtFNSHJ0A=";
  };

  depsBuildBuild = [
    pkg-config
  ];

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
    glib
    python3
  ]
  ++ lib.optionals withIntrospection [
    gi-docgen
    gobject-introspection
    vala
  ];

  buildInputs = [
    sqlite
    libpsl
    glib.out
    brotli
    libnghttp2
  ];

  propagatedBuildInputs = [
    glib
  ];

  mesonBuildType = "release";

  mesonFlags = [
    "-Dtls_check=false"
    "-Dgssapi=disabled"
    "-Dntlm=disabled"
    "-Dautobahn=disabled"
    "-Dpkcs11_tests=disabled"
    "-Dsysprof=disabled"

    (lib.mesonEnable "docs" withIntrospection)
    (lib.mesonEnable "introspection" withIntrospection)
    (lib.mesonEnable "vapi" withIntrospection)
  ];

  # TODO: For some reason the pkg-config setup hook does not pick this up.
  env.PKG_CONFIG_PATH = "${libnghttp2.dev}/lib/pkgconfig";

  separateDebugInfo = true;

  postPatch = ''
    patchShebangs libsoup/
  '';

  postFixup = ''
    # Cannot be in postInstall, otherwise _multioutDocs hook in preFixup will move right back.
    moveToOutput "share/doc" "$devdoc"
  '';

  meta = {
    description = "HTTP client/server library for GNOME";
    homepage = "https://gitlab.gnome.org/GNOME/libsoup";
    license = lib.licenses.lgpl2Plus;
    changelog = "https://gitlab.gnome.org/GNOME/libsoup/-/blob/${finalAttrs.version}/NEWS";
    maintainers = [ ];
    platforms = lib.platforms.linux;
  };
})
