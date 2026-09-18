{
  lib,
  stdenv,
  fetchurl,
  replaceVars,
  meson,
  nasm,
  ninja,
  pkg-config,
  python3,
  gst-plugins-base,
  orc,
  bzip2,
  gettext,
  libGL,
  libdv,
  libvpx,
  libdrm,
  speex,
  flac,
  taglib,
  libshout,
  cairo,
  gdk-pixbuf,
  libcaca,
  libsoup_3,
  libpulseaudio,
  libintl,
  libxml2,
  lame,
  mpg123,
  enableX11 ? stdenv.hostPlatform.isLinux,
  libxtst,
  libxi,
  libxfixes,
  libxext,
  libxdamage,
  ncurses,
  enableWayland ? stdenv.hostPlatform.isLinux,
  wayland,
  wayland-protocols,
  libgudev,
  glib,
  openssl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gst-plugins-good";
  version = "1.28.5";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "https://gstreamer.freedesktop.org/src/gst-plugins-good/gst-plugins-good-${finalAttrs.version}.tar.xz";
    hash = "sha256-WLRdJKHXeznXu32czG4tdrvyhhiZjDNcFj8Y5vlKkyQ=";
  };

  patches = [
    (replaceVars ./souploader.diff {
      nixLibSoup3Path = "${lib.getLib libsoup_3}/lib";
    })
  ];

  strictDeps = true;

  depsBuildBuild = [ pkg-config ];

  nativeBuildInputs = [
    pkg-config
    python3
    meson
    meson.configurePhaseHook
    ninja
    gettext
    orc
    libshout
    glib
  ]
  ++ lib.optionals stdenv.hostPlatform.isx86_64 [
    nasm
  ]
  ++ lib.optionals enableWayland [
    wayland-protocols
  ];

  buildInputs = [
    gst-plugins-base
    orc
    bzip2
    libdv
    libvpx
    speex
    flac
    taglib
    cairo
    gdk-pixbuf
    libcaca
    libsoup_3
    libshout
    libxml2
    lame
    mpg123
    libintl
    ncurses
    openssl
  ]
  ++ lib.optionals enableX11 [
    libxext
    libxfixes
    libxdamage
    libxtst
    libxi
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    libdrm
    libGL
    libpulseaudio
    libgudev
  ]
  ++ lib.optionals enableWayland [
    wayland
  ];

  mesonFeatures = {
    examples = false;
    glib_debug = false;
    doc = false;
    asm = true;
    qt5 = false;
    qt6 = false;
    gtk3 = false;
    # Deps not yet in core-pkgs
    twolame = false;
    amrnb = false;
    amrwbdec = false;
    aalib = false;
    wavpack = false;
    jack = false;
    v4l2 = false;
    v4l2-gudev = false;
    dv1394 = false;
    rpicamsrc = false;
    ximagesrc = enableX11;
    oss4 = stdenv.hostPlatform.isLinux;
    oss = stdenv.hostPlatform.isLinux;
    pulse = stdenv.hostPlatform.isLinux;
  };

  postPatch = ''
    patchShebangs \
      scripts/extract-release-date-from-doap-file.py
  '';

  env = {
    NIX_LDFLAGS = "-lncurses";
  };

  dontWrapQtApps = true;

  preFixup = ''
    moveToOutput "lib/gstreamer-1.0/pkgconfig" "$dev"
  '';

  meta = {
    description = "GStreamer Good Plugins";
    homepage = "https://gstreamer.freedesktop.org";
    license = lib.licenses.lgpl2Plus;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
