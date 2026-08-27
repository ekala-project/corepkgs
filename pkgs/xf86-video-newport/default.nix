{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  xorgproto,
  xorg-server,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-video-newport";
  version = "0.2.4";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-newport-0.2.4.tar.bz2";
    sha256 = "1yafmp23jrfdmc094i6a4dsizapsc9v0pl65cpc8w1kvn7343k4i";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    xorg-server
  ];
  meta.broken = true;
  meta.identifiers.cpeParts.vendor = "x.org";
})
