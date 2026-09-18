{
  stdenv,
  lib,
  fetchFromGitHub,
  fetchpatch,
  pkg-config,
  meson,
  ninja,
  python3,
  glib,
  gobject-introspection,
  buildPackages,
  withIntrospection ?
    lib.meta.availableOn stdenv.hostPlatform gobject-introspection
    && stdenv.hostPlatform.emulatorAvailable buildPackages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "graphene";
  version = "1.10.8";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitHub {
    owner = "ebassi";
    repo = "graphene";
    rev = finalAttrs.version;
    sha256 = "P6JQhSktzvyMHatP/iojNGXPmcsxsFxdYerXzS23ojI=";
  };

  depsBuildBuild = [
    pkg-config
  ];

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
    python3
  ]
  ++ lib.optionals withIntrospection [
    gobject-introspection
  ];

  buildInputs = [
    glib
  ];

  mesonEntries = {
    gtk_doc = false;
    installed_tests = false;
    ${if stdenv.hostPlatform.isAarch32 then "arm_neon" else null} = false;
  };

  mesonFeatures = {
    introspection = withIntrospection;
  };

  doCheck = true;

  postPatch = ''
    patchShebangs tests/gen-installed-test.py
  '';

  meta = {
    description = "Thin layer of graphic data types";
    homepage = "https://github.com/ebassi/graphene";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
