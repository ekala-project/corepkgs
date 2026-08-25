{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  xorgproto,
  libdrm,
  udev,
  libpciaccess,
  xorg-server,
  spice-protocol,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-video-qxl";
  version = "0.1.6";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-qxl-0.1.6.tar.xz";
    sha256 = "0pwncx60r1xxk8kpp9a46ga5h7k7hjqf14726v0gra27vdc9blra";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libdrm
    udev
    libpciaccess
    xorg-server
    spice-protocol
  ];
})
