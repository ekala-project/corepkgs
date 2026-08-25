{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  xorgproto,
  libevdev ? null,
  libx11,
  libXi,
  xorg-server,
  libXtst,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-input-synaptics";
  version = "1.10.0";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-input-synaptics-1.10.0.tar.xz";
    sha256 = "1hmm3g6ab4bs4hm6kmv508fdc8kr2blzb1vsz1lhipcf0vdnmhp0";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libevdev
    libx11
    libXi
    xorg-server
    libXtst
  ];
  outputs = [
    "out"
    "dev"
  ];
  configureFlags = [
    "--with-sdkdir=${placeholder "dev"}/include/xorg"
    "--with-xorg-conf-dir=${placeholder "out"}/share/X11/xorg.conf.d"
  ];
  meta = {
    pkgConfigModules = [ "xorg-synaptics" ];
  };
})
