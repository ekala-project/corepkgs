{
  stdenv,
  lib,
  fetchurl,
  meson,
  ninja,
  pkg-config,
  python3,
  gettext,
  gobject-introspection,
  gst-plugins-base,
  gst-plugins-bad,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gst-rtsp-server";
  version = "1.28.5";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "https://gstreamer.freedesktop.org/src/gst-rtsp-server/gst-rtsp-server-${finalAttrs.version}.tar.xz";
    hash = "sha256-fhn93rEmG+vD7Dl4V/7dXHcSm2arUniP2trQURdWYiU=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    gettext
    gobject-introspection
    pkg-config
    python3
  ];

  buildInputs = [
    gst-plugins-base
    gst-plugins-bad
  ];

  mesonFeatures = {
    glib_debug = false;
    examples = false;
    doc = false;
  };

  postPatch = ''
    patchShebangs \
      scripts/extract-release-date-from-doap-file.py
  '';

  preFixup = ''
    moveToOutput "lib/gstreamer-1.0/pkgconfig" "$dev"
  '';

  meta = {
    description = "GStreamer RTSP server";
    homepage = "https://gstreamer.freedesktop.org";
    license = lib.licenses.lgpl2Plus;
    platforms = lib.platforms.unix;
  };
})
