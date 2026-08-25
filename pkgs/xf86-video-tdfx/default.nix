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
  pname = "xf86-video-tdfx";
  version = "1.5.0";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-tdfx-1.5.0.tar.bz2";
    sha256 = "0qc5wzwf1n65si9rc37bh224pzahh7gp67vfimbxs0b9yvhq0i9g";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libdrm
    libpciaccess
    xorg-server
  ];
})
