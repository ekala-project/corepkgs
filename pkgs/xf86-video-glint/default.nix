{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  libpciaccess,
  xorgproto,
  xorg-server,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-video-glint";
  version = "1.2.9";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-glint-1.2.9.tar.bz2";
    sha256 = "1lkpspvrvrp9s539bhfdjfh4andaqyk63l6zjn8m3km95smk6a45";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    libpciaccess
    xorgproto
    xorg-server
  ];
  meta.broken = true;
})
