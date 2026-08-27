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
  pname = "xf86-video-tga";
  version = "1.2.2";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-tga-1.2.2.tar.bz2";
    sha256 = "0cb161lvdgi6qnf1sfz722qn38q7kgakcvj7b45ba3i0020828r0";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libpciaccess
    xorg-server
  ];
  meta.broken = true;
  meta.identifiers.cpeParts.vendor = "x.org";
})
