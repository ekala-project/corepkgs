{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  xorgproto,
  libx11,
  libxext,
  libXi,
  libXinerama,
  libXrandr,
}:

buildXorgPackage (finalAttrs: {
  pname = "xinput";
  version = "1.6.4";
  src = fetchurl {
    url = "mirror://xorg/individual/app/xinput-1.6.4.tar.xz";
    sha256 = "1j2pf28c54apr56v1fmvprp657n6x4sdrv8f24rx3138cl6x015d";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    xorgproto
    libx11
    libxext
    libXi
    libXinerama
    libXrandr
  ];
  meta.mainProgram = "xinput";
})
