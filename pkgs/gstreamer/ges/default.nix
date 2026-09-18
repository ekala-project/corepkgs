{
  lib,
  stdenv,
  fetchurl,
  meson,
  ninja,
  pkg-config,
  python3,
  bash-completion,
  gst-plugins-base,
  gst-plugins-bad,
  gst-devtools,
  libxml2,
  flex,
  gettext,
  gobject-introspection,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gst-editing-services";
  version = "1.28.5";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "https://gstreamer.freedesktop.org/src/gst-editing-services/gst-editing-services-${finalAttrs.version}.tar.xz";
    hash = "sha256-0C+d99108qUCQ6b6XjJ8+71cEhKc57bnPXDAhTJJGog=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
    gettext
    gobject-introspection
    python3
    flex
  ];

  buildInputs = [
    bash-completion
    libxml2
    gst-devtools
    python3
  ];

  propagatedBuildInputs = [
    gst-plugins-base
    gst-plugins-bad
  ];

  mesonFeatures = {
    doc = false;
    tests = false;
  };

  postPatch = ''
    patchShebangs \
      scripts/extract-release-date-from-doap-file.py
  '';

  preFixup = ''
    moveToOutput "lib/gstreamer-1.0/pkgconfig" "$dev"
  '';

  meta = {
    description = "Library for creation of audio/video non-linear editors";
    homepage = "https://gstreamer.freedesktop.org";
    license = lib.licenses.lgpl2Plus;
    platforms = lib.platforms.unix;
  };
})
