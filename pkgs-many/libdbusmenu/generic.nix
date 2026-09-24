{
  withGtk3 ? false,
  mkVariantPassthru,
  ...
}@variantArgs:

{
  stdenv,
  fetchurl,
  lib,
  file,
  pkg-config,
  intltool,
  glib,
  dbus-glib,
  json-glib,
  gobject-introspection,
  vala,
  gtk3 ? null,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libdbusmenu-${if withGtk3 then "gtk3" else "glib"}";
  version = "16.04.0";

  src = fetchurl {
    url = "https://launchpad.net/dbusmenu/${lib.versions.majorMinor finalAttrs.version}/${finalAttrs.version}/+download/libdbusmenu-${finalAttrs.version}.tar.gz";
    sha256 = "12l7z8dhl917iy9h02sxmpclnhkdjryn08r8i4sr8l3lrlm4mk5r";
  };

  nativeBuildInputs = [
    vala
    pkg-config
    intltool
    gobject-introspection
  ];

  buildInputs = [
    glib
    dbus-glib
    json-glib
  ]
  ++ lib.optional withGtk3 gtk3;

  patches = [
    ./requires-glib.patch
  ];

  postPatch = ''
    for f in {configure,ltmain.sh,m4/libtool.m4}; do
      substituteInPlace $f \
        --replace /usr/bin/file ${file}/bin/file
    done
  '';

  # https://projects.archlinux.org/svntogit/community.git/tree/trunk/PKGBUILD?h=packages/libdbusmenu
  preConfigure = ''
    export HAVE_VALGRIND_TRUE="#"
    export HAVE_VALGRIND_FALSE=""
  '';

  configureFlags = [
    "CFLAGS=-Wno-error"
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    (if withGtk3 then "--with-gtk=3" else "--disable-gtk")
    "--disable-dumper"
    "--disable-scrollkeeper"
  ];

  installFlags = [
    "sysconfdir=${placeholder "out"}/etc"
    "localstatedir=\${TMPDIR}"
    "typelibdir=${placeholder "out"}/lib/girepository-1.0"
  ];

  passthru = mkVariantPassthru variantArgs // {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "Library for passing menu structures across DBus";
    homepage = "https://launchpad.net/dbusmenu";
    license = with lib.licenses; [
      gpl3
      lgpl21
      lgpl3
    ];
    pkgConfigModules = [
      "dbusmenu-glib-0.4"
      "dbusmenu-jsonloader-0.4"
    ]
    ++ lib.optional withGtk3 "dbusmenu-gtk3-0.4";
    platforms = lib.platforms.unix;
  };
})
