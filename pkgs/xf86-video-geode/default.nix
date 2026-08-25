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
  pname = "xf86-video-geode";
  version = "2.18.1";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-geode-2.18.1.tar.xz";
    sha256 = "0a8c6g3ndzf76rrrm3dwzmndcdy4y2qfai4324sdkmi8k9szicjr";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libpciaccess
    xorg-server
  ];
  meta.broken = true;
})
