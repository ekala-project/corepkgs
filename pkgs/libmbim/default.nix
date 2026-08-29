{
  lib,
  stdenv,
  fetchFromGitLab,
  meson,
  ninja,
  pkg-config,
  glib,
  python3,
  help2man,
  bash-completion,
  bash,
  buildPackages,
  withIntrospection ?
    lib.meta.availableOn stdenv.hostPlatform gobject-introspection
    && stdenv.hostPlatform.emulatorAvailable buildPackages,
  withDocs ? stdenv.hostPlatform == stdenv.buildPlatform,
  gobject-introspection,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libmbim";
  version = "1.34.0";

  outputs = [
    "out"
    "dev"
  ]
  ++ lib.optionals withDocs [ "man" ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "mobile-broadband";
    repo = "libmbim";
    rev = finalAttrs.version;
    hash = "sha256-NhSjW1ZK4XFv7L/IaoTjN5ojwjTDQa178k73zoaneuE=";
  };

  mesonFlags = [
    "-Dudevdir=${placeholder "out"}/lib/udev"
    (lib.mesonBool "introspection" withIntrospection)
    (lib.mesonBool "man" withDocs)
  ];

  strictDeps = true;

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
    python3
  ]
  ++ lib.optionals withDocs [
    help2man
  ]
  ++ lib.optionals withIntrospection [
    gobject-introspection
  ];

  buildInputs = [
    glib
    bash-completion
    bash
  ];

  postPatch = ''
    patchShebangs \
      build-aux/mbim-codegen/mbim-codegen
  '';

  meta = {
    homepage = "https://www.freedesktop.org/wiki/Software/libmbim/";
    description = "Library for talking to WWAN modems and devices which speak the Mobile Interface Broadband Model (MBIM) protocol";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "freedesktop" finalAttrs.version;
  };
})
