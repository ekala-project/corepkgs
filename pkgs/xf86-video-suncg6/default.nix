{
  lib,
  buildXorgPackage,
  stdenv,
  pkg-config,
  fetchurl,
  xorgproto,
  xorg-server,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-video-suncg6";
  version = "1.1.3";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-suncg6-1.1.3.tar.xz";
    sha256 = "16c3g5m0f5y9nx2x6w9jdzbs9yr6xhq31j37dcffxbsskmfxq57w";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    xorg-server
  ];
  meta.broken = stdenv.hostPlatform.isDarwin;
})
