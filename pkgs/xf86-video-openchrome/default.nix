{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  fetchpatch,
  xorgproto,
  libdrm,
  udev,
  libpciaccess,
  libx11,
  libxext,
  xorg-server,
  libXvMC,
  libXv,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-video-openchrome";
  version = "0.6.0";
  src = fetchurl {
    url = "mirror://xorg/individual/driver/xf86-video-openchrome-0.6.0.tar.bz2";
    sha256 = "0x9gq3hw6k661k82ikd1y2kkk4dmgv310xr5q59dwn4k6z37aafs";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libdrm
    udev
    libpciaccess
    libx11
    libxext
    xorg-server
    libXvMC
    libXv
  ];
  patches = [
    (fetchpatch {
      name = "fno-common.patch";
      url = "https://github.com/freedesktop/openchrome-xf86-video-openchrome/commit/edb46574d4686c59e80569ba236d537097dcdd0e.patch";
      sha256 = "0xqawg9zzwb7x5vaf3in60isbkl3zfjq0wcnfi45s3hiii943sxz";
    })
  ];
  meta.identifiers.cpeParts.vendor = "x.org";
})
