{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  xorgproto,
  libx11,
  libxext,
  libxt,
}:

buildXorgPackage (finalAttrs: {
  pname = "libxtrap";
  version = "1.0.1";
  src = fetchurl {
    url = "mirror://xorg/individual/lib/libxtrap-1.0.1.tar.bz2";
    sha256 = "0bi5wxj6avim61yidh9fd3j4n8czxias5m8vss9vhxjnk1aksdwg";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libx11
    libxext
    libxt
  ];
  meta = {
    pkgConfigModules = [ "xtrap" ];
  };
})
