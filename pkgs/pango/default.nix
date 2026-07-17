{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  cairo,
  harfbuzz,
  libintl,
  libthai,
  fribidi,
  makeFontsConf,
  dejavu_fonts,
  meson,
  ninja,
  glib,
  python3,
  docutils,
  x11Support ? !stdenv.hostPlatform.isDarwin,
  libxft,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pango";
  version = "1.57.1";

  outputs = [
    "bin"
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "mirror://gnome/sources/pango/${lib.versions.majorMinor finalAttrs.version}/pango-${finalAttrs.version}.tar.xz";
    hash = "sha256-5l1tEXCA3Drut9i0s7UY9zg6oubPziMRfGI81iR2TC8=";
  };

  depsBuildBuild = [
    pkg-config
  ];

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    glib
    pkg-config
    python3
    docutils
  ];

  buildInputs = [
    fribidi
    libthai
  ];

  propagatedBuildInputs = [
    cairo
    glib
    harfbuzz
  ]
  ++ lib.optional (libintl != null) libintl
  ++ lib.optionals x11Support [
    libxft
  ];

  mesonFlags = [
    (lib.mesonBool "documentation" false)
    (lib.mesonBool "man-pages" true)
    (lib.mesonEnable "introspection" false)
    (lib.mesonEnable "xft" x11Support)
  ];

  mesonBuildType = "release";

  env.FONTCONFIG_FILE = makeFontsConf {
    fontDirectories = [ dejavu_fonts ];
  };

  passthru.tests = {
    pkg-config = testers.hasPkgConfigModules {
      package = finalAttrs.finalPackage;
    };
  };

  meta = {
    description = "Library for laying out and rendering of text, with an emphasis on internationalization";
    homepage = "https://www.pango.org/";
    license = lib.licenses.lgpl2Plus;
    platforms = lib.platforms.unix;
    maintainers = [ ];
    pkgConfigModules = [
      "pango"
      "pangocairo"
      "pangofc"
      "pangoft2"
      "pangoot"
    ];
  };
})
