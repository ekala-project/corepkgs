{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  glib,
  freetype,
  meson,
  ninja,
  python3,
  graphite2,
  withGraphite2 ? true,
  withIcu ? false,
  icu,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "harfbuzz";
  version = "13.2.1";

  src = fetchurl {
    url = "https://github.com/harfbuzz/harfbuzz/releases/download/${finalAttrs.version}/harfbuzz-${finalAttrs.version}.tar.xz";
    hash = "sha256-ZpXaPrfhvgqjCS/k2BQzoztH9FGSWcdZ1ynjqaVcFCk=";
  };

  patches = [ ./disable-check-symbols-test.patch ];

  postPatch = ''
    patchShebangs src/*.py test
  '';

  outputs = [
    "out"
    "dev"
  ];
  outputBin = "dev";

  mesonFlags = [
    (lib.mesonEnable "cairo" false)
    (lib.mesonEnable "raster" false)
    (lib.mesonEnable "chafa" false)
    (lib.mesonEnable "coretext" false)
    (lib.mesonEnable "graphite" withGraphite2)
    (lib.mesonEnable "icu" withIcu)
    (lib.mesonEnable "introspection" false)
    (lib.mesonEnable "docs" false)
  ];

  depsBuildBuild = [
    pkg-config
  ];

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
    python3
    glib
  ];

  buildInputs = [
    glib
    freetype
  ];

  propagatedBuildInputs = lib.optional withGraphite2 graphite2 ++ lib.optional withIcu icu;

  mesonBuildType = "release";

  passthru.tests = {
    pkg-config = testers.hasPkgConfigModules {
      package = finalAttrs.finalPackage;
    };
  };

  meta = {
    description = "OpenType text shaping engine";
    homepage = "https://harfbuzz.github.io/";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    pkgConfigModules = [
      "harfbuzz"
      "harfbuzz-gobject"
      "harfbuzz-subset"
    ];
    maintainers = [ ];
  };
})
