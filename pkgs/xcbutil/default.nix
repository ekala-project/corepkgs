{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  libxcb,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libxcb-util";
  version = "0.4.1";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxcb-util";
    tag = "xcb-util-${finalAttrs.version}";
    hash = "sha256-glIAfKeIUN+5qV6mk6ts8GZLP0P5AffEQYrNxXWmBgo=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];
  buildInputs = [ libxcb ];
  propagatedBuildInputs = [ libxcb ];

  meta = {
    description = "XCB utility libraries";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxcb-util";
    license = lib.licenses.x11;
    pkgConfigModules = [
      "xcb-atom"
      "xcb-aux"
      "xcb-event"
      "xcb-util"
    ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = {
      vendor = "x.org";
      product = "xcb-util";
    };
  };
})
