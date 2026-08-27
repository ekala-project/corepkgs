{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  m4,
  python3,
  xcb-proto,
  libxcb,
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

  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
    m4
    python3
  ];

  buildInputs = [
    xcb-proto
    libxcb
  ];

  propagatedBuildInputs = [ libxcb ];

  meta = {
    description = "XCB utility library that gives human readable names to error, event & request codes";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxcb-errors";
    license = lib.licenses.x11;
    pkgConfigModules = [ "xcb-errors" ];
    platforms = lib.platforms.unix;
  };
})
