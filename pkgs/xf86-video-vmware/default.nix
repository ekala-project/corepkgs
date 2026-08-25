{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  xorgproto,
  libdrm,
  udev,
  libpciaccess,
  libx11,
  libxext,
  xorg-server,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-video-vmware";
  version = "13.4.0";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-vmware-13.4.0.tar.xz";
    sha256 = "06mq7spifsrpbwq9b8kn2cn61xq6mpkq6lvh4qi6xk2yxpjixlxf";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libdrm
    udev
    libpciaccess
    libx11
    libxext
    xorg-server
  ];
  env.NIX_CFLAGS_COMPILE = toString [ "-Wno-error=address" ];
  meta.platforms = [
    "i686-linux"
    "x86_64-linux"
  ];
})
