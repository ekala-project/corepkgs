{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  libXfont2,
  xorgproto,
  xtrans,
}:

buildXorgPackage (finalAttrs: {
  pname = "xfs";
  version = "1.2.2";
  src = fetchurl {
    url = "mirror://xorg/individual/app/xfs-1.2.2.tar.xz";
    sha256 = "1k4f15nrgmqkvsn48hnl1j4giwxpmcpdrnq0bq7b6hg265ix82xp";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    libXfont2
    xorgproto
    xtrans
  ];
  meta.mainProgram = "xfs";
  meta.identifiers.cpeParts.vendor = "x.org";
})
