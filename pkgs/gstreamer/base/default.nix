{
  stdenv,
  fetchurl,
  lib,
  pkg-config,
  meson,
  ninja,
  gettext,
  python3,
  gstreamer,
  graphene,
  orc,
  pango,
  libtheora,
  libintl,
  libopus,
  isocodes,
  libjpeg,
  libpng,
  libvorbis,
  libGL,
  withIntrospection ?
    lib.meta.availableOn stdenv.hostPlatform gobject-introspection
    && stdenv.hostPlatform.emulatorAvailable buildPackages,
  buildPackages,
  gobject-introspection,
  enableX11 ? stdenv.hostPlatform.isLinux,
  libxext,
  libxi,
  libxv,
  libdrm,
  enableWayland ? stdenv.hostPlatform.isLinux,
  wayland-scanner,
  wayland,
  wayland-protocols,
  enableAlsa ? stdenv.hostPlatform.isLinux,
  alsa-lib,
  enableCocoa ? stdenv.hostPlatform.isDarwin,
  enableGl ? (enableX11 || enableWayland || enableCocoa),
  enableCdparanoia ? (!stdenv.hostPlatform.isDarwin),
  cdparanoia,
  glib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gst-plugins-base";
  version = "1.28.5";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "https://gstreamer.freedesktop.org/src/gst-plugins-base/gst-plugins-base-${finalAttrs.version}.tar.xz";
    hash = "sha256-d28ZIo+R/SW79U2YUFl+FYUH9ZSHKlK5toFOJCm0Pqo=";
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
    python3
    gettext
    orc
    glib
    gstreamer
  ]
  ++ lib.optionals withIntrospection [
    gobject-introspection
  ]
  ++ lib.optionals enableWayland [
    wayland-scanner
  ];

  buildInputs = [
    graphene
    orc
    libtheora
    libintl
    libopus
    isocodes
    libpng
    libjpeg
    libvorbis
    pango
  ]
  ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
    libdrm
    libGL
  ]
  ++ lib.optionals enableAlsa [
    alsa-lib
  ]
  ++ lib.optionals enableX11 [
    libxext
    libxi
    libxv
  ]
  ++ lib.optionals enableWayland [
    wayland
    wayland-protocols
  ]
  ++ lib.optional enableCdparanoia cdparanoia;

  propagatedBuildInputs = [
    gstreamer
  ]
  ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
    libdrm
  ];

  mesonEntries = {
    gl_winsys = lib.concatStringsSep "," (
      lib.optional enableX11 "x11"
      ++ lib.optional enableWayland "wayland"
      ++ lib.optional enableCocoa "cocoa"
    );
  };

  mesonFeatures = {
    glib_debug = false;
    examples = false;
    introspection = withIntrospection;
    doc = false;
    libvisual = false;
    tremor = false;
    vorbis = true;
    tests = stdenv.buildPlatform == stdenv.hostPlatform;
    x11 = enableX11;
    xi = enableX11;
    xshm = enableX11;
    xvideo = enableX11;
    gl = enableGl;
    alsa = enableAlsa;
    cdparanoia = enableCdparanoia;
    drm = !stdenv.hostPlatform.isDarwin;
  };

  postPatch = ''
    patchShebangs \
      scripts/meson-pkg-config-file-fixup.py \
      scripts/extract-release-date-from-doap-file.py
  '';

  hardeningDisable = [ "format" ];

  preFixup = ''
    moveToOutput "lib/gstreamer-1.0/pkgconfig" "$dev"
  '';

  passthru = {
    glEnabled = enableGl;
    waylandEnabled = enableWayland;
  };

  meta = {
    description = "Base GStreamer plug-ins and helper libraries";
    homepage = "https://gstreamer.freedesktop.org";
    license = lib.licenses.lgpl2Plus;
    platforms = lib.platforms.unix;
  };
})
