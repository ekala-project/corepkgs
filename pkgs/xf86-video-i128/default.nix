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
  pname = "xf86-video-i128";
  version = "1.4.1";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-i128-1.4.1.tar.xz";
    sha256 = "0imwmkam09wpp3z3iaw9i4hysxicrrax7i3p0l2glgp3zw9var3h";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libpciaccess
    xorg-server
  ];
  meta.broken = true;
})
