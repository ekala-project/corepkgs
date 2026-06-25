{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  gettext,
  xorgproto,
  libx11,
  libxext,
  libxt,
  gzip,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libxpm";
  version = "3.5.18";

  outputs = [
    "bin"
    "dev"
    "out"
  ];

  src = fetchurl {
    url = "mirror://xorg/individual/lib/libXpm-${finalAttrs.version}.tar.xz";
    hash = "sha256-tO15v8cYAA7e6DfVUcNShvC4RXbbDOB7u+vmCkr/oeQ=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
    gettext
  ];

  buildInputs = [
    xorgproto
    libx11
    libxext
    libxt
  ];

  propagatedBuildInputs = [ libx11 ];

  env = {
    XPM_PATH_GZIP = lib.makeBinPath [ gzip ];
    XPM_PATH_UNCOMPRESS = lib.makeBinPath [ gzip ];
  };

  meta = {
    description = "X Pixmap (XPM) image file format library";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxpm";
    license = with lib.licenses; [
      x11
      mit
    ];
    mainProgram = "sxpm";
    maintainers = [ ];
    pkgConfigModules = [ "xpm" ];
    platforms = lib.platforms.unix;
  };
})
