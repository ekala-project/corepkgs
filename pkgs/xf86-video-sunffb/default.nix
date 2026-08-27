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
  pname = "xf86-video-sunffb";
  version = "1.2.3";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-sunffb-1.2.3.tar.xz";
    sha256 = "0pf4ddh09ww7sxpzs5gr9pxh3gdwkg3f54067cp802nkw1n8vypi";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    xorg-server
  ];
  meta.broken = stdenv.hostPlatform.isDarwin;
  meta.identifiers.cpeParts.vendor = "x.org";
})
