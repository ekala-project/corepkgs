{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  libxcb,
  xorgproto,
  m4,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "xcb-util-wm";
  version = "0.4.2";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxcb-wm";
    tag = "xcb-util-wm-${finalAttrs.version}";
    hash = "sha256-MKgArUOmwRRcMqLcVyNeZo3Z3BSNS4/9sc/w5nnFKZQ=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    m4
    pkg-config
    util-macros
  ];

  buildInputs = [
    libxcb
    xorgproto
  ];

  propagatedBuildInputs = [ libxcb ];

  meta = {
    description = "XCB client and window-manager helpers for ICCCM & EWMH.";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxcb-wm";
    license = lib.licenses.x11;
    pkgConfigModules = [
      "xcb-ewmh"
      "xcb-icccm"
    ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = {
      vendor = "x.org";
      product = "xcb-util-wm";
    };
  };
})
