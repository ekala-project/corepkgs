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
  pname = "xf86-video-fbdev";
  version = "0.5.1";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-fbdev-0.5.1.tar.xz";
    sha256 = "11zk8whari4m99ad3w30xwcjkgya4xbcpmg8710q14phkbxw0aww";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libpciaccess
    xorg-server
  ];
  meta.identifiers.cpeParts.vendor = "x.org";
})
