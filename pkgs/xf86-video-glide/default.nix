{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  xorgproto,
  xorg-server,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-video-glide";
  version = "1.2.2";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-glide-1.2.2.tar.bz2";
    sha256 = "1vaav6kx4n00q4fawgqnjmbdkppl0dir2dkrj4ad372mxrvl9c4y";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    xorg-server
  ];
  meta.broken = true;
  meta.identifiers.cpeParts.vendor = "x.org";
})
