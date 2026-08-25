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
  pname = "xf86-video-ark";
  version = "0.7.6";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-ark-0.7.6.tar.xz";
    sha256 = "0p88blr3zgy47jc4aqivc6ypj4zq9pad1cl70wwz9xig29w9xk2s";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libpciaccess
    xorg-server
  ];
  meta.broken = true;
})
