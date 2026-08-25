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
  pname = "xf86-video-mga";
  version = "2.1.0";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-mga-2.1.0.tar.xz";
    sha256 = "0wxbcgg5i4yq22pbc50567877z8irxhqzgl3sk6vf5zs9szmvy3v";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libdrm
    libpciaccess
    xorg-server
  ];
})
