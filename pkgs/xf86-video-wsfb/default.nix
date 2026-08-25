{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  xorg-server,
  xorgproto,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-video-wsfb";
  version = "0.4.0";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-wsfb-0.4.0.tar.bz2";
    sha256 = "0hr8397wpd0by1hc47fqqrnaw3qdqd8aqgwgzv38w5k3l3jy6p4p";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorg-server
    xorgproto
  ];
  meta.broken = true;
})
