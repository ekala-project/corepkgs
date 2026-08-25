{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  libx11,
  libxmu,
  xorgproto,
}:

buildXorgPackage (finalAttrs: {
  pname = "xpr";
  version = "1.2.0";
  src = fetchurl {
    url = "mirror://xorg/individual/app/xpr-1.2.0.tar.xz";
    sha256 = "1hyf6mc2l7lzkf21d5j4z6glg9y455hlsg8lv2lz028k6gw0554b";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    libx11
    libxmu
    xorgproto
  ];
  meta.mainProgram = "xpr";
})
