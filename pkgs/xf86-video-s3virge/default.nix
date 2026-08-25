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
  pname = "xf86-video-s3virge";
  version = "1.11.1";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-s3virge-1.11.1.tar.xz";
    sha256 = "1qzfcq3rlpfdb6qxz8hrp9py1q11vyzl4iqxip1vpgfnfn83vl6f";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libpciaccess
    xorg-server
  ];
  meta.broken = true;
})
