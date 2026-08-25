{
  lib,
  buildXorgPackage,
  stdenv,
  pkg-config,
  fetchurl,
  libdmx ? null,
  libx11,
  libxcb,
  libXcomposite,
  libxext,
  libXi,
  libXinerama,
  xorgproto,
  libxrender,
  libXtst,
  libXxf86dga,
  libXxf86misc,
  libXxf86vm,
}:

buildXorgPackage (finalAttrs: {
  pname = "xdpyinfo";
  version = "1.3.4";
  src = fetchurl {
    url = "mirror://xorg/individual/app/xdpyinfo-1.3.4.tar.xz";
    sha256 = "0aw2yhx4ys22231yihkzhnw9jsyzksl4yyf3sx0689npvf0sbbd8";
  };
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    libdmx
    libx11
    libxcb
    libXcomposite
    libxext
    libXi
    libXinerama
    xorgproto
    libxrender
    libXtst
    libXxf86dga
    libXxf86misc
    libXxf86vm
  ];
  configureFlags = lib.optional (
    stdenv.hostPlatform != stdenv.buildPlatform
  ) "--enable-malloc0returnsnull";
  preConfigure = lib.optionalString stdenv.hostPlatform.isStatic ''
    export NIX_CFLAGS_LINK="$NIX_CFLAGS_LINK -lXau -lXdmcp"
  '';
  meta.mainProgram = "xdpyinfo";
})
