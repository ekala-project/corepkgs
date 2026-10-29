{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  libxcb,
  testers,
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

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ libxcb ];
  propagatedBuildInputs = [ libxcb ];

  passthru.tests.testLink = testers.pkg-config.testLink { package = finalAttrs.finalPackage; };

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
