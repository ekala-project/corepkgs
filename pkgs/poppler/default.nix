{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitLab,
  cairo,
  cmake,
  boost,
  curl,
  fontconfig,
  freetype,
  glib,
  lcms2,
  libjpeg,
  libtiff,
  ninja,
  nss,
  openjpeg,
  pkg-config,
  python3,
  zlib,
  gobject-introspection,
  gpgme,
  gpgmeSupport ? false,
  introspectionSupport ? false,
  utils ? false,
  minimal ? false,
  suffix ? "glib",
}:

let
  mkFlag = optset: flag: "-DENABLE_${flag}=${if optset then "on" else "off"}";

  testData = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "poppler";
    repo = "test";
    rev = "f0068e9c530017ad811d1f28b95f9b7f59264e37";
    hash = "sha256-Xf8duSh0r1o09b5BKB7mBvzrMfXYlzTuTOuK2ZCeItc=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "poppler-${suffix}";
  version = "26.06.0";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "https://poppler.freedesktop.org/poppler-${finalAttrs.version}.tar.xz";
    hash = "sha256-TLTlo9yMte7HUciiPIuhn2H5be3AzQfSruawyOLPa6Q=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    ninja
    pkg-config
    python3
  ]
  ++ lib.optionals (!minimal) [
    glib # for glib-mkenums
  ];

  buildInputs = [
    boost
  ];

  # TODO: reduce propagation to necessary libs
  propagatedBuildInputs = [
    zlib
    freetype
    fontconfig
    libjpeg
    openjpeg
  ]
  ++ lib.optionals (!minimal) [
    cairo
    lcms2
    libtiff
    curl
    nss
  ]
  ++ lib.optionals introspectionSupport [
    gobject-introspection
  ]
  ++ lib.optionals gpgmeSupport [
    gpgme
  ];

  cmakeFlags = [
    (mkFlag true "UNSTABLE_API_ABI_HEADERS")
    (mkFlag (!minimal) "GLIB")
    (mkFlag (!minimal) "CPP")
    (mkFlag (!minimal) "LIBCURL")
    (mkFlag (!minimal) "LCMS")
    (mkFlag (!minimal) "LIBTIFF")
    (mkFlag (!minimal) "NSS3")
    (mkFlag utils "UTILS")
    (mkFlag false "QT5")
    (mkFlag false "QT6")
    (mkFlag gpgmeSupport "GPGME")
  ];

  cmakeBuildType = "Release";

  disallowedReferences = lib.optional finalAttrs.finalPackage.doCheck testData;

  preConfigure = lib.optionalString finalAttrs.finalPackage.doCheck ''
    # The test data directory needs to be writable during the test phase.
    mkdir -p $TMPDIR/testdata
    cp -r --no-preserve=mode ${testData}/* $TMPDIR/testdata
    cmakeFlagsArray+=(-DTESTDATADIR=$TMPDIR/testdata)
  '';

  doCheck = true;

  passthru = {
    inherit testData;
  };

  meta = {
    homepage = "https://poppler.freedesktop.org/";
    changelog = "https://gitlab.freedesktop.org/poppler/poppler/-/blob/poppler-${finalAttrs.version}/NEWS";
    description = "PDF rendering library";
    longDescription = ''
      Poppler is a PDF rendering library based on the xpdf-3.0 code base. In
      addition it provides a number of tools that can be installed separately.
    '';
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.all;
    maintainers = [ ];
    pkgConfigModules = [
      "poppler"
    ]
    ++ lib.optionals (!minimal) [ "poppler-cpp" ]
    ++ lib.optionals introspectionSupport [ "poppler-glib" ];
  };
})
