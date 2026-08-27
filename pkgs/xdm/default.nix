{
  lib,
  buildXorgPackage,
  stdenv,
  pkg-config,
  fetchurl,
  libx11,
  libxau,
  libxaw,
  libxdmcp,
  libxext,
  libxft,
  libXinerama,
  libxmu,
  libxpm,
  xorgproto,
  libxrender,
  libxt,
  wrapWithXFileSearchPathHook,
  libxcrypt,
}:

buildXorgPackage (finalAttrs: {
  pname = "xdm";
  version = "1.1.17";
  src = fetchurl {
    url = "mirror://xorg/individual/app/xdm-1.1.17.tar.xz";
    sha256 = "0spbxjxxrnfxf8gqncd7bry3z7dvr74ba987cx9iq0qsj7qax54l";
  };
  nativeBuildInputs = [
    pkg-config
    wrapWithXFileSearchPathHook
  ];
  buildInputs = [
    libx11
    libxau
    libxaw
    libxdmcp
    libxext
    libxft
    libXinerama
    libxmu
    libxpm
    xorgproto
    libxrender
    libxt
    libxcrypt
  ];
  configureFlags = [
    "ac_cv_path_RAWCPP=${stdenv.cc.targetPrefix}cpp"
  ]
  ++ lib.optionals (stdenv.buildPlatform != stdenv.hostPlatform) [
    "ac_cv_file__dev_urandom=true"
    "ac_cv_file__dev_random=true"
  ];
  meta.mainProgram = "xdm";
  meta.identifiers.cpeParts.vendor = "x.org";
})
