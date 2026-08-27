{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  libx11,
  libxkbfile,
  xorgproto,
}:

buildXorgPackage (finalAttrs: {
  pname = "xkbprint";
  version = "1.0.7";
  src = fetchurl {
    url = "mirror://xorg/individual/app/xkbprint-1.0.7.tar.xz";
    sha256 = "1k2rm8lvc2klcdz2s3mymb9a2ahgwqwkgg67v3phv7ij6304jkqw";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    libx11
    libxkbfile
    xorgproto
  ];
  meta.mainProgram = "xkbprint";
  meta.identifiers.cpeParts.vendor = "x.org";
})
