{
  stdenv,
  fetchurl,
  meson,
  ninja,
  pkg-config,
  python3,
  gst-plugins-base,
  orc,
  gettext,
  a52dec,
  libcdio,
  libdvdread ? null,
  libmpeg2,
  x264,
  libintl,
  lib,
  enableGplPlugins ? true,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gst-plugins-ugly";
  version = "1.28.5";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "https://gstreamer.freedesktop.org/src/gst-plugins-ugly/gst-plugins-ugly-${finalAttrs.version}.tar.xz";
    hash = "sha256-DvTPnDyaXndqbKjRkKMYYzkbaBmAJSFDuCKymqgx4SA=";
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
    gst-plugins-base
    orc
    libintl
  ]
  ++ lib.optionals enableGplPlugins [
    a52dec
    libcdio
    libmpeg2
    x264
  ]
  ++ lib.optionals (enableGplPlugins && libdvdread != null) [
    libdvdread
  ];

  mesonFeatures = {
    glib_debug = false;
    sidplay = false;
    doc = false;
    gpl = enableGplPlugins;
    dvdread = enableGplPlugins && libdvdread != null;
    a52dec = enableGplPlugins;
    cdio = enableGplPlugins;
    mpeg2dec = enableGplPlugins;
    x264 = enableGplPlugins;
  };

  postPatch = ''
    patchShebangs \
      scripts/extract-release-date-from-doap-file.py
  '';

  preFixup = ''
    moveToOutput "lib/gstreamer-1.0/pkgconfig" "$dev"
  '';

  meta = {
    description = "GStreamer Ugly Plugins";
    homepage = "https://gstreamer.freedesktop.org";
    license = if enableGplPlugins then lib.licenses.gpl2Plus else lib.licenses.lgpl2Plus;
    platforms = lib.platforms.unix;
  };
})
