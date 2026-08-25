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
  pname = "xf86-video-nv";
  version = "2.1.23";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-nv-2.1.23.tar.xz";
    sha256 = "1jlap6xjn4pfwg9ab8fxm5mwf4dqfywp70bgc0071m7k66jbv3f6";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libpciaccess
    xorg-server
  ];
})
