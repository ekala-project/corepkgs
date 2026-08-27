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
  pname = "xf86-video-vesa";
  version = "2.6.0";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-vesa-2.6.0.tar.xz";
    sha256 = "1ccvaigb1f1kz8nxxjmkfn598nabd92p16rx1g35kxm8n5qjf20h";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libpciaccess
    xorg-server
  ];
  meta.identifiers.cpeParts.vendor = "x.org";
})
