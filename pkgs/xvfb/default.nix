# xvfb — virtual framebuffer X server, used by many packages to run tests.
# This is a minimal build of xorg-server with only Xvfb enabled.
{
  lib,
  stdenv,
  xorg-server,
  dri-pkgconfig-stub,
  libdrm,
  libGL,
  mesa-gl-headers,
  pixman,
  libXfont2 ? null,
  xtrans,
  libxcvt,
  libxshmfence,
  xkbcomp,
  xkeyboard-config,
}:

xorg-server.overrideAttrs (old: {
  configureFlags = [
    "--enable-xvfb"
    "--disable-xorg"
    "--disable-xquartz"
    "--disable-xwayland"
    "--with-xkb-bin-directory=${xkbcomp}/bin"
    "--with-xkb-path=${xkeyboard-config}/share/X11/xkb"
    "--with-xkb-output=$out/share/X11/xkb/compiled"
  ]
  ++ lib.optional stdenv.hostPlatform.isDarwin "--without-dtrace";

  buildInputs =
    old.buildInputs
    ++ [
      dri-pkgconfig-stub
      libdrm
      libGL
      mesa-gl-headers
      pixman
      xtrans
      libxcvt
      libxshmfence
    ]
    ++ lib.optional (libXfont2 != null) libXfont2;
})
