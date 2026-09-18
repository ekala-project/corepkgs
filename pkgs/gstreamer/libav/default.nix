{
  stdenv,
  lib,
  fetchurl,
  meson,
  ninja,
  pkg-config,
  python3,
  gstreamer,
  gst-plugins-base,
  gettext,
  ffmpeg_8-headless,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gst-libav";
  version = "1.28.5";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "https://gstreamer.freedesktop.org/src/gst-libav/gst-libav-${finalAttrs.version}.tar.xz";
    hash = "sha256-RShUZWBW8LFlEaHZrU8mef9eWofIn5DPfuXewAXdseQ=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    gettext
    pkg-config
    python3
  ];

  buildInputs = [
    gstreamer
    gst-plugins-base
    ffmpeg_8-headless
  ];

  mesonFeatures = {
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
    description = "FFmpeg plugin for GStreamer";
    homepage = "https://gstreamer.freedesktop.org";
    license = lib.licenses.lgpl2Plus;
    platforms = lib.platforms.unix;
  };
})
