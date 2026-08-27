{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  xorgproto,
  libpciaccess,
  xorg-server,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-video-chips";
  version = "1.5.0";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-chips-1.5.0.tar.xz";
    sha256 = "1cyljd3h2hjv42ldqimf4lllqhb8cma6p3n979kr8nn81rjdkhw4";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libpciaccess
    xorg-server
  ];
  meta.identifiers.cpeParts.vendor = "x.org";
})
