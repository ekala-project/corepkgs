{
  lib,
  buildXorgPackage,
  pkg-config,
  fetchFromGitLab,
  autoreconfHook,
  cairo,
  xorgproto,
  libdrm,
  libpng,
  udev,
  libpciaccess,
  libx11,
  xcbutil,
  libxcb,
  libXcursor,
  libXdamage,
  libxext,
  libXfixes,
  xorg-server,
  libXrandr,
  libxrender,
  libxshmfence,
  libXtst,
  libXvMC,
  libXScrnSaver,
  libXv,
  pixman,
  util-macros ? null,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-video-intel";
  # the update script only works with released tarballs :-/
  name = "xf86-video-intel-2024-05-06";
  version = "2.99.917";
  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "driver";
    repo = "xf86-video-intel";
    rev = "ce811e78882d9f31636351dfe65351f4ded52c74";
    sha256 = "sha256-PKCxFHMwxgbew0gkxNBKiezWuqlFG6bWLkmtUNyoF8Q=";
  };
  nativeBuildInputs = [
    pkg-config
    autoreconfHook
    util-macros
    xorg-server
  ];
  buildInputs = [
    cairo
    xorgproto
    libdrm
    libpng
    udev
    libpciaccess
    libx11
    xcbutil
    libxcb
    libXcursor
    libXdamage
    libxext
    libXfixes
    xorg-server
    libXrandr
    libxrender
    libxshmfence
    libXtst
    libXvMC
    libXScrnSaver
    libXv
    pixman
  ];
  configureFlags = [
    "--with-default-dri=3"
    "--enable-tools"
  ];
  patches = [ ../xorg/use_crocus_and_iris.patch ];

  meta.platforms = [
    "i686-linux"
    "x86_64-linux"
  ];
  meta.identifiers.cpeParts.vendor = "x.org";
})
