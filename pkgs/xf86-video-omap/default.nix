{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  xorgproto,
  libdrm,
  xorg-server,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-video-omap";
  version = "0.4.5";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-omap-0.4.5.tar.bz2";
    sha256 = "0nmbrx6913dc724y8wj2p6vqfbj5zdjfmsl037v627jj0whx9rwk";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libdrm
    xorg-server
  ];
  env.NIX_CFLAGS_COMPILE = toString [ "-Wno-error=format-overflow" ];
})
