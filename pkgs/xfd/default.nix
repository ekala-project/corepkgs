{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  libxkbfile,
  fontconfig,
  libxaw,
  libxft,
  libxmu,
  xorgproto,
  libxrender,
  libxt,
  gettext,
  wrapWithXFileSearchPathHook,
}:

buildXorgPackage (finalAttrs: {
  pname = "xfd";
  version = "1.1.4";
  src = fetchurl {
    url = "mirror://xorg/individual/app/xfd-1.1.4.tar.xz";
    sha256 = "1zbnj0z28dx2rm2h7pjwcz7z1jnl28gz0v9xn3hs2igxcvxhyiym";
  };
  nativeBuildInputs = [
    pkg-config
    gettext
    wrapWithXFileSearchPathHook
  ];
  buildInputs = [
    libxkbfile
    fontconfig
    libxaw
    libxft
    libxmu
    xorgproto
    libxrender
    libxt
  ];
  meta.mainProgram = "xfd";
})
