{
  lib,
  stdenv,
  fetchurl,
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

  src = fetchurl {
    url = "mirror://xorg/individual/xcb/xcb-util-${finalAttrs.version}.tar.xz";
    hash = "sha256-Wr47u9jlTw+j7JRSkbfo+oz9PMzENxj4dYQw+UEm5RI=";
  };

  strictDeps = true;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ libxcb ];
  propagatedBuildInputs = [ libxcb ];

  meta = {
    description = "XCB utility libraries";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxcb-util";
    license = lib.licenses.x11;
    maintainers = [ ];
    pkgConfigModules = [
      "xcb-atom"
      "xcb-aux"
      "xcb-event"
      "xcb-util"
    ];
    platforms = lib.platforms.unix;
  };
})
