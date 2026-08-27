{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  libx11,
  libxmu,
  xorgproto,
  mcpp,
}:

buildXorgPackage (finalAttrs: {
  pname = "xrdb";
  version = "1.2.2";
  src = fetchurl {
    url = "mirror://xorg/individual/app/xrdb-1.2.2.tar.xz";
    sha256 = "1x1ka0zbcw66a06jvsy92bvnsj9vxbvnq1hbn1az4f0v4fmzrx9i";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    libx11
    libxmu
    xorgproto
  ];
  configureFlags = [ "--with-cpp=${mcpp}/bin/mcpp" ];
  meta.mainProgram = "xrdb";
  meta.identifiers.cpeParts.vendor = "x.org";
})
