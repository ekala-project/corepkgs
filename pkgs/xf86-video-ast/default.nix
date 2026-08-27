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
  pname = "xf86-video-ast";
  version = "1.2.0";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-ast-1.2.0.tar.xz";
    sha256 = "14sx6dm0nmbf1fs8cazmak0aqjpjpv9wv7v09w86ff04m7f4gal6";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libpciaccess
    xorg-server
  ];
  meta.identifiers.cpeParts.vendor = "x.org";
})
