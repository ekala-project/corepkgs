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
  xorg-server,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-video-amdgpu";
  version = "23.0.0";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-amdgpu-23.0.0.tar.xz";
    sha256 = "0qf0kjh6pww5abxmqa4c9sfa2qq1hq4p8qcgqpfd1kpkcvmg012g";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libgbm
    libGL
    libdrm
    udev
    xorg-server
  ];
  configureFlags = [ "--with-xorg-conf-dir=$(out)/share/X11/xorg.conf.d" ];
})
