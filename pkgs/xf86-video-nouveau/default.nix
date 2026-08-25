{
  lib,
  buildXorgPackage,
  buildPackages,
  pkg-config,
  fetchurl,
  autoreconfHook,
  xorgproto,
  libdrm,
  udev,
  libpciaccess,
  xorg-server,
  util-macros ? null,
}:

buildXorgPackage (finalAttrs: {
  pname = "xf86-video-nouveau";
  version = "3ee7cbca8f9144a3bb5be7f71ce70558f548d268";
  src = fetchurl {
    url = "https://gitlab.freedesktop.org/xorg/driver/xf86-video-nouveau/-/archive/3ee7cbca8f9144a3bb5be7f71ce70558f548d268/xf86-video-nouveau-3ee7cbca8f9144a3bb5be7f71ce70558f548d268.tar.bz2";
    sha256 = "0rhs3z274jdzd82pcsl25xn8hmw6i4cxs2kwfnphpfhxbbkiq7wl";
  };
  nativeBuildInputs = [
    pkg-config
    autoreconfHook
    util-macros
    xorg-server # for xorg-server.m4 macros
  ];
  buildInputs = [
    xorgproto
    libdrm
    udev
    libpciaccess
    xorg-server
  ];
  # fixes `implicit declaration of function 'wfbScreenInit'; did you mean 'fbScreenInit'?
  NIX_CFLAGS_COMPILE = "-Wno-error=implicit-function-declaration";
})
