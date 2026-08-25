{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  libx11,
  libxt,
  libxtrap,
}:

buildXorgPackage (finalAttrs: {
  pname = "xtrap";
  version = "1.0.3";
  src = fetchurl {
    url = "mirror://xorg/individual/app/xtrap-1.0.3.tar.bz2";
    sha256 = "0sqm4j1zflk1s94iq4waa70hna1xcys88v9a70w0vdw66czhvj2j";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    libx11
    libxt
    libxtrap
  ];
})
