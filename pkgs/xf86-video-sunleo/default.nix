{
  lib,
  buildXorgPackage,
  stdenv,
  pkg-config,
  fetchurl,
  xorgproto,
  xorg-server,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-video-sunleo";
  version = "1.2.3";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-sunleo-1.2.3.tar.xz";
    sha256 = "1px670aiqyzddl1nz3xx1lmri39irajrqw6dskirs2a64jgp3dpc";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    xorg-server
  ];
  meta.broken = stdenv.hostPlatform.isDarwin;
  meta.identifiers.cpeParts.vendor = "x.org";
})
