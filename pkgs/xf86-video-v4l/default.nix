{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  xorgproto,
  xorg-server,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-video-v4l";
  version = "0.3.0";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-v4l-0.3.0.tar.bz2";
    sha256 = "084x4p4avy72mgm2vnnvkicw3419i6pp3wxik8zqh7gmq4xv5z75";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    xorg-server
  ];
  meta.broken = true;
  meta.identifiers.cpeParts.vendor = "x.org";
})
