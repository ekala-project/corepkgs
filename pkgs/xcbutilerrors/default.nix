{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  gnum4,
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

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxcb-errors";
    tag = "xcb-util-errors-${finalAttrs.version}";
    hash = "sha256-HbfjryhbiGJGkzN0k5GIAjc1uABXWBYyaXIjIqT+cwE=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    gnum4
    pkg-config
    python3
    util-macros
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
    identifiers.cpeParts = {
      vendor = "x.org";
      product = "xcb-util-errors";
    };
  };
})
