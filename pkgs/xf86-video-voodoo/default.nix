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
  pname = "xf86-video-voodoo";
  version = "1.2.6";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-voodoo-1.2.6.tar.xz";
    sha256 = "00pn5826aazsdipf7ny03s1lypzid31fmswl8y2hrgf07bq76ab2";
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
