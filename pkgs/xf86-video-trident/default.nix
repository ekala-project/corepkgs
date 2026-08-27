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
  pname = "xf86-video-trident";
  version = "1.4.0";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-trident-1.4.0.tar.xz";
    sha256 = "16qqn1brz50mwcy42zi1wsw9af56qadsaaiwm9hn1p6plyf22xkz";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libpciaccess
    xorg-server
  ];
  meta.identifiers.cpeParts.vendor = "x.org";
})
