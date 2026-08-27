{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  xorgproto,
  libgbm,
  libGL,
  libdrm,
  udev,
  libpciaccess,
  xorg-server,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-video-ati";
  version = "22.0.0";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-ati-22.0.0.tar.xz";
    sha256 = "0vdznwx78alhbb05paw2xd65hcsila2kqflwwnbpq8pnsdbbpj68";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libgbm
    libGL
    libdrm
    udev
    libpciaccess
    xorg-server
  ];
  meta.identifiers.cpeParts.vendor = "x.org";
})
