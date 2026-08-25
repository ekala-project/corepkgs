{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  libx11,
  libxaw,
  libxft,
  libxkbfile,
  libxmu,
  xorgproto,
  libxrender,
  libxt,
  wrapWithXFileSearchPathHook,
}:

buildXorgPackage (finalAttrs: {
  pname = "xclock";
  version = "1.1.1";
  src = fetchurl {
    url = "mirror://xorg/individual/app/xclock-1.1.1.tar.xz";
    sha256 = "0b3l1zwz2b1cn46f8pd480b835j9anadf929vqpll107iyzylz6z";
  };
  nativeBuildInputs = [
    pkg-config
    wrapWithXFileSearchPathHook
  ];
  buildInputs = [
    libx11
    libxaw
    libxft
    libxkbfile
    libxmu
    xorgproto
    libxrender
    libxt
  ];
  meta.mainProgram = "xclock";
})
