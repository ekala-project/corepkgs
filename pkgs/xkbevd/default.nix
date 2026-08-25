{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  libx11,
  libxkbfile,
}:

buildXorgPackage (finalAttrs: {
  pname = "xkbevd";
  version = "1.1.6";
  src = fetchurl {
    url = "mirror://xorg/individual/app/xkbevd-1.1.6.tar.xz";
    sha256 = "0gh73dsf4ic683k9zn2nj9bpff6dmv3gzcb3zx186mpq9kw03d6r";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    libx11
    libxkbfile
  ];
  meta.mainProgram = "xkbevd";
})
