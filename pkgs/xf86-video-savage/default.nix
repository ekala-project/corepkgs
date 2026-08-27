{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  xorgproto,
  libdrm,
  libpciaccess,
  xorg-server,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-video-savage";
  version = "2.4.1";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-savage-2.4.1.tar.xz";
    sha256 = "1bqhgldb6yahpgav7g7cyc4kl5pm3mgkq8w2qncj36311hb92hb7";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libdrm
    libpciaccess
    xorg-server
  ];
  meta.identifiers.cpeParts.vendor = "x.org";
})
