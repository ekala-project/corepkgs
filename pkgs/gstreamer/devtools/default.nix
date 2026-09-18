{
  lib,
  stdenv,
  fetchurl,
  cairo,
  meson,
  ninja,
  pkg-config,
  gstreamer,
  gst-plugins-base,
  gst-plugins-bad,
  gst-rtsp-server,
  python3,
  gobject-introspection,
  json-glib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gst-devtools";
  version = "1.28.5";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "https://gstreamer.freedesktop.org/src/gst-devtools/gst-devtools-${finalAttrs.version}.tar.xz";
    hash = "sha256-dFkEXbMdbkRgC8vgEdySV1AmiHDnuQ9+ego69KIcCeU=";
  };

  strictDeps = true;

  depsBuildBuild = [
    pkg-config
  ];

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
    gobject-introspection
  ];

  buildInputs = [
    cairo
    python3
    json-glib
  ];

  propagatedBuildInputs = [
    gstreamer
    gst-plugins-base
    gst-plugins-bad
    gst-rtsp-server
  ];

  mesonFeatures = {
    doc = false;
    dots_viewer = false;
  };

  preFixup = ''
    moveToOutput "lib/gstreamer-1.0/pkgconfig" "$dev"
  '';

  meta = {
    description = "Integration testing infrastructure for the GStreamer framework";
    homepage = "https://gstreamer.freedesktop.org";
    license = lib.licenses.lgpl2Plus;
    platforms = lib.platforms.unix;
  };
})
