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
  pname = "xf86-video-siliconmotion";
  version = "1.7.10";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-siliconmotion-1.7.10.tar.xz";
    sha256 = "1h4g2mqxshaxii416ldw0aqy6cxnsbnzayfin51xm2526dw9q18n";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libpciaccess
    xorg-server
  ];
  meta.platforms = [
    "i686-linux"
    "x86_64-linux"
  ];
  meta.identifiers.cpeParts.vendor = "x.org";
})
