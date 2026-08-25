{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  libxkbfile,
  libx11,
  xorgproto,
}:

buildXorgPackage (finalAttrs: {
  pname = "xwd";
  version = "1.0.9";
  src = fetchurl {
    url = "mirror://xorg/individual/app/xwd-1.0.9.tar.xz";
    sha256 = "0gxx3y9zlh13jgwkayxljm6i58ng8jc1xzqv2g8s7d3yjj21n4nw";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    libxkbfile
    libx11
    xorgproto
  ];
  meta.mainProgram = "xwd";
})
