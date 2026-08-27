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
  pname = "xf86-video-vboxvideo";
  version = "1.0.1";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-vboxvideo-1.0.1.tar.xz";
    sha256 = "12kzgf516mbdygpni0jzm3dv60vz6vf704f3hgc6pi9bgpy6bz4f";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libpciaccess
    xorg-server
  ];
  meta.identifiers.cpeParts.vendor = "x.org";
})
