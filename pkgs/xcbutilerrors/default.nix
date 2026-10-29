{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  m4,
  python3,
  xcb-proto,
  libxcb,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "xcb-util-errors";
  version = "1.0.1";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "mirror://xorg/individual/xcb/xcb-util-errors-${finalAttrs.version}.tar.xz";
    hash = "sha256-VijIe5hCWa2Se6zYpClYMZw2vfSwZYh4A8nYIPuA81c=";
  };

  nativeBuildInputs = [
    m4
    pkg-config
    python3
  ];

  buildInputs = [
    xcb-proto
    libxcb
  ];

  propagatedBuildInputs = [ libxcb ];

  passthru.tests.testLink = testers.pkg-config.testLink { package = finalAttrs.finalPackage; };

  meta = {
    description = "XCB utility library that gives human readable names to error, event & request codes";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxcb-errors";
    license = lib.licenses.x11;
    pkgConfigModules = [ "xcb-errors" ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = {
      vendor = "x.org";
      product = "xcb-util-errors";
    };
  };
})
