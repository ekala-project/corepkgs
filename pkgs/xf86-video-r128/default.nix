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
  pname = "xf86-video-r128";
  version = "6.13.0";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-r128-6.13.0.tar.xz";
    sha256 = "0igpfgls5nx4sz8a7yppr42qi37prqmxsy08zqbxbv81q9dfs2zj";
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
