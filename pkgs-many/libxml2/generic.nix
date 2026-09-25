{
  version,
  src-tag-prefix,
  src-hash,
  freezeUpdateScript ? false,
  packageOlder,
  packageAtLeast,
  ...
}:

{
  stdenv,
  bootstrapStdenv,
  lib,
  pkg-config,
  autoreconfHook,
  python3,
  doxygen,
  ncurses,
  findXMLCatalogs,
  libiconv,
  pythonSupport ? false,
  icuSupport ? false,
  icu,
  zlibSupport ? false,
  zlib,
  enableShared ? !stdenv.hostPlatform.isMinGW && !stdenv.hostPlatform.isStatic,
  enableStatic ? !enableShared,
  gnome,
  testers,
  enableHttp ? false,
  fetchFromGitLab,
  fetchpatch,

  # for passthru.tests
  libxslt,
  fontconfig,
}:

let
  # libxml2 is a dependency of xcbuild. Avoid an infinite recursion by using a bootstrap stdenv
  # that does not propagate xcrun.
  stdenv' = if stdenv.hostPlatform.isDarwin then bootstrapStdenv else stdenv;
in
stdenv'.mkDerivation (finalAttrs: {
  pname = "libxml2";
  inherit version;

  src = fetchFromGitLab {
    domain = "gitlab.gnome.org";
    owner = "GNOME";
    repo = "libxml2";
    tag = "${src-tag-prefix}${version}";
    hash = src-hash;
  };

  outputs = [
    "bin"
    "dev"
    "out"
  ]
  ++ lib.optional pythonSupport "py"
  ++ lib.optional (enableStatic && enableShared) "static";
  outputMan = "bin";

  patches = lib.optionals (packageOlder "2.15") [
    # same as upstream patch but fixed conflict and added required import:
    # https://gitlab.gnome.org/GNOME/libxml2/-/commit/acbbeef9f5dcdcc901c5f3fa14d583ef8cfd22f0.diff
    ./CVE-2025-6021.patch
    (fetchpatch {
      name = "CVE-2025-49794-49796.patch";
      url = "https://gitlab.gnome.org/GNOME/libxml2/-/commit/f7ebc65f05bffded58d1e1b2138eb124c2e44f21.patch";
      hash = "sha256-p5Vc/lkakHKsxuFNnCQtFczjqFJBeLnCwIwv2GnrQco=";
    })
    (fetchpatch {
      name = "CVE-2025-49795.patch";
      url = "https://gitlab.gnome.org/GNOME/libxml2/-/commit/c24909ba2601848825b49a60f988222da3019667.patch";
      hash = "sha256-vICVSb+X89TTE4QY92/v/6fRk77Hy9vzEWWsADHqMlk=";
      excludes = [ "runtest.c" ]; # tests were rewritten in C and are on schematron for 2.13.x, meaning this does not apply
    })
    # same as upstream, fixed conflicts
    # https://gitlab.gnome.org/GNOME/libxml2/-/commit/c340e419505cf4bf1d9ed7019a87cc00ec200434
    ./CVE-2025-6170.patch

    # Unmerged ABI-breaking patch required to fix the following security issues:
    # - https://gitlab.gnome.org/GNOME/libxslt/-/issues/139
    # - https://gitlab.gnome.org/GNOME/libxslt/-/issues/140
    # See also https://gitlab.gnome.org/GNOME/libxml2/-/issues/906
    # Source: https://github.com/chromium/chromium/blob/4fb4ae8ce3daa399c3d8ca67f2dfb9deffcc7007/third_party/libxml/chromium/xml-attr-extra.patch
    ./xml-attr-extra.patch
  ];

  nativeBuildInputs = [
    pkg-config
    autoreconfHook
  ]
  ++ lib.optionals pythonSupport [
    doxygen
  ];

  buildInputs =
    lib.optionals pythonSupport [
      ncurses
      python3
    ]
    ++ lib.optionals zlibSupport [
      zlib
    ];

  propagatedBuildInputs = [
    findXMLCatalogs
  ]
  ++ lib.optionals (stdenv.hostPlatform.isDarwin || stdenv.hostPlatform.isMinGW) [
    libiconv
  ]
  ++ lib.optionals icuSupport [
    icu
  ];

  configureFlags = [
    "--exec-prefix=${placeholder "dev"}"
    (lib.enableFeature enableStatic "static")
    (lib.enableFeature enableShared "shared")
    (lib.withFeature icuSupport "icu")
    (lib.withFeature pythonSupport "python")
    (lib.optionalString pythonSupport "PYTHON=${python3.pythonOnBuildForHost.interpreter}")
    (lib.withFeature enableHttp "http")
    (lib.withFeature zlibSupport "zlib")
    (lib.withFeature false "docs") # docs are built with xsltproc, which would be a cyclic dependency
  ];

  installFlags = lib.optionals pythonSupport [
    "pythondir=\"${placeholder "py"}/${python3.sitePackages}\""
    "pyexecdir=\"${placeholder "py"}/${python3.sitePackages}\""
  ];

  doCheck = (stdenv.hostPlatform == stdenv.buildPlatform) && stdenv.hostPlatform.libc != "musl";
  preCheck = lib.optional stdenv.hostPlatform.isDarwin ''
    export DYLD_LIBRARY_PATH="$PWD/.libs:$DYLD_LIBRARY_PATH"
  '';

  preConfigure = lib.optionalString (lib.versionAtLeast stdenv.hostPlatform.darwinMinVersion "11") ''
    MACOSX_DEPLOYMENT_TARGET=10.16
  '';

  preInstall = lib.optionalString pythonSupport ''
    substituteInPlace python/libxml2mod.la --replace-fail "$dev/${python3.sitePackages}" "$py/${python3.sitePackages}"
  '';

  postFixup = ''
    moveToOutput bin/xml2-config "$dev"
    moveToOutput lib/xml2Conf.sh "$dev"
  ''
  + lib.optionalString (enableStatic && enableShared) ''
    moveToOutput lib/libxml2.a "$static"
  '';

  passthru = {
    inherit pythonSupport;

    updateScript = gnome.updateScript {
      packageName = "libxml2";
      versionPolicy = "none";
      freeze = freezeUpdateScript;
    };
    tests = {
      pkg-config = testers.hasPkgConfigModules {
        package = finalAttrs.finalPackage;
      };
      cmake-config = testers.hasCmakeConfigModules {
        moduleNames = [ "LibXml2" ];
        package = finalAttrs.finalPackage;
      };
      inherit libxslt fontconfig;
    };
  };

  meta = {
    homepage = "https://gitlab.gnome.org/GNOME/libxml2";
    description = "XML parsing library for C";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    changelog = "https://gitlab.gnome.org/GNOME/libxml2/-/releases/v${version}";
    pkgConfigModules = [ "libxml-2.0" ];
    # Python limits cross-compilation to an allowlist of host OSes.
    # https://github.com/python/cpython/blob/dfad678d7024ab86d265d84ed45999e031a03691/configure.ac#L534-L562
    broken =
      pythonSupport
      && !(
        enableShared
        && (
          stdenv.hostPlatform == stdenv.buildPlatform
          || stdenv.hostPlatform.isCygwin
          || stdenv.hostPlatform.isLinux
          || stdenv.hostPlatform.isWasi
        )
      );
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "xmlsoft" finalAttrs.version;
  };
})
