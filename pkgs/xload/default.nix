{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchurl,
  libx11,
  libxaw,
  libxmu,
  xorgproto,
  libxt,
  gettext,
  wrapWithXFileSearchPathHook,
}:

buildXorgPackage (finalAttrs: {
  pname = "xload";
  version = "1.2.0";
  src = fetchurl {
    url = "mirror://xorg/individual/app/xload-1.2.0.tar.xz";
    sha256 = "104snn0rpnc91bmgj797cj6sgmkrp43n9mg20wbmr8p14kbfc3rc";
  };
  nativeBuildInputs = [
    pkg-config
    gettext
    wrapWithXFileSearchPathHook
  ];
  buildInputs = [
    libx11
    libxaw
    libxmu
    xorgproto
    libxt
  ];
  meta.mainProgram = "xload";
})
