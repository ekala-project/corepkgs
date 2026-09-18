{
  lib,
  stdenv,
  fetchurl,
  replaceVars,
  meson,
  ninja,
  gettext,
  pkg-config,
  python3,
  gst-plugins-base,
  orc,
  gstreamer,
  gobject-introspection,
  wayland-scanner,
  libass ? null,
  lcms2,
  webrtc-audio-processing,
  webrtcAudioProcessingSupport ? lib.meta.availableOn stdenv.hostPlatform webrtc-audio-processing.v1,
  libopus,
  pango,
  curl,
  json-glib,
  libde265,
  libdrm,
  libdvdnav ? null,
  libdvdread ? null,
  libgudev,
  qrencode,
  libsndfile,
  libusb1,
  openjpeg,
  libwebp,
  gnutls,
  libGL,
  libintl,
  openssl,
  libxml2,
  srt,
  x265,
  svt-av1,
  libva,
  wayland-protocols,
  wayland,
  addDriverRunpath,
  enableGplPlugins ? true,
  bluezSupport ? stdenv.hostPlatform.isLinux,
  bluez,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "gst-plugins-bad";
  version = "1.28.5";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "https://gstreamer.freedesktop.org/src/gst-plugins-bad/gst-plugins-bad-${finalAttrs.version}.tar.xz";
    hash = "sha256-2K9V+u8pWMGoZjdRR17kb1Fkh3z02MWRPqkG7xgK63E=";
  };

  patches = [
    (replaceVars ./fix-paths.patch {
      inherit (addDriverRunpath) driverLink;
    })
  ];

  strictDeps = true;

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
    orc
    python3
    gettext
    gstreamer
    gobject-introspection
  ]
  ++ lib.optionals (gst-plugins-base.waylandEnabled && stdenv.hostPlatform.isLinux) [
    wayland-scanner
  ];

  buildInputs = [
    gst-plugins-base
    orc
    json-glib
    lcms2
    libopus
    openjpeg
    curl.dev
    libde265
    qrencode
    libsndfile
    libusb1
    pango
    libwebp
    gnutls
    openssl
    libxml2
    libintl
    srt
    svt-av1
  ]
  ++ lib.optionals (libass != null) [
    libass
  ]
  ++ lib.optionals enableGplPlugins [
    x265
  ]
  ++ lib.optionals (enableGplPlugins && libdvdnav != null) [
    libdvdnav
  ]
  ++ lib.optionals (enableGplPlugins && libdvdread != null) [
    libdvdread
  ]
  ++ lib.optionals bluezSupport [
    bluez
  ]
  ++ lib.optionals (gst-plugins-base.waylandEnabled && stdenv.hostPlatform.isLinux) [
    libva
    wayland
    wayland-protocols
  ]
  ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
    libdrm
    libgudev
    libGL
  ]
  ++ lib.optionals webrtcAudioProcessingSupport [
    webrtc-audio-processing.v1
  ];

  mesonFlags = [
    "-Dauto_features=auto"
    "-Dexamples=disabled"
    "-Dglib_debug=disabled"
    "-Ddoc=disabled"

    "-Damfcodec=disabled"
    "-Dandroidmedia=disabled"
    "-Davtp=disabled"
    "-Dcuda-nvmm=disabled"
    "-Ddirectshow=disabled"
    "-Dqt6d3d11=disabled"
    "-Ddts=disabled"
    "-Dzbar=disabled"
    "-Dfaac=disabled"
    "-Diqa=disabled"
    "-Dlcevcencoder=disabled"
    "-Dmagicleap=disabled"
    "-Dmsdk=disabled"
    "-Dmusepack=disabled"
    "-Dnvcomp=disabled"
    "-Dnvdswrapper=disabled"
    "-Dopenni2=disabled"
    "-Dopensles=disabled"
    "-Dsvthevcenc=disabled"
    "-Dsvtjpegxs=disabled"
    "-Dteletext=disabled"
    "-Dtinyalsa=disabled"
    "-Dvoamrwbenc=disabled"
    "-Dvulkan=disabled"
    "-Dwasapi=disabled"
    "-Dwasapi2=disabled"
    "-Dwpe=disabled"
    "-Dwpe2=disabled"
    "-Dgs=disabled"
    "-Donnx=disabled"
    "-Dopenaptx=disabled"
    "-Dopencv=disabled"
    "-Daja=disabled"
    "-Daom=disabled"
    "-Dmicrodns=disabled"
    "-Dbluez=${if bluezSupport then "enabled" else "disabled"}"
    (lib.mesonEnable "openh264" false)
    (lib.mesonEnable "directfb" false)
    (lib.mesonEnable "lcevcdecoder" false)
    (lib.mesonEnable "ldac" false)
    (lib.mesonEnable "webrtcdsp" webrtcAudioProcessingSupport)
    (lib.mesonEnable "isac" webrtcAudioProcessingSupport)
    # Disabled deps not yet in core-pkgs
    "-Dflite=disabled"
    "-Dgsm=disabled"
    "-Ddc1394=disabled"
    "-Dneon=disabled"
    "-Dopenal=disabled"
    "-Dopenexr=disabled"
    "-Dopenmpt=disabled"
    "-Drtmp2=disabled"
    "-Dsbc=disabled"
    "-Dsoundtouch=disabled"
    "-Dspandsp=disabled"
    "-Dsrtp=disabled"
    "-Dwildmidi=disabled"
    "-Dfluidsynth=disabled"
    "-Dgme=disabled"
    "-Dvoaacenc=disabled"
    "-Dzxing=disabled"
    "-Dsctp=disabled"
    "-Dbs2b=disabled"
    "-Dmodplug=disabled"
    "-Dchromaprint=disabled"
    "-Dfdkaac=disabled"
    "-Dladspa=disabled"
    "-Dladspa-rdf=disabled"
    "-Dlv2=disabled"
    "-Drtmp=disabled"
    "-Dlc3=disabled"
    "-Dassrender=${if libass != null then "enabled" else "disabled"}"
    "-Dwebrtc=disabled"
    "-Dgtk3=disabled"
    "-Drsvg=disabled"
    "-Dcurl-ssh2=disabled"
    "-Dshm=disabled"
    "-Ddtls=disabled"
  ]
  ++ lib.mapAttrsToList lib.mesonEnable {
    mpeghdec = false;
    tflite = false;
  }
  ++ lib.optionals (!stdenv.hostPlatform.isLinux || !stdenv.hostPlatform.isx86) [
    "-Dnvcodec=disabled"
  ]
  ++ lib.optionals (!stdenv.hostPlatform.isLinux || !gst-plugins-base.waylandEnabled) [
    "-Dva=disabled"
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    "-Dkms=disabled"
    "-Ddvb=disabled"
    "-Dfbdev=disabled"
    "-Duvcgadget=disabled"
    "-Duvch264=disabled"
    "-Dv4l2codecs=disabled"
  ]
  ++
    lib.optionals
      (!stdenv.hostPlatform.isLinux || !stdenv.hostPlatform.isx86_64 || !gst-plugins-base.waylandEnabled)
      [
        "-Dqsv=disabled"
      ]
  ++ lib.optionals (!gst-plugins-base.glEnabled) [
    "-Dgl=disabled"
    "-Dapplemedia=disabled"
  ]
  ++ lib.optionals (!gst-plugins-base.waylandEnabled) [
    "-Dwayland=disabled"
  ]
  ++ (
    if enableGplPlugins then
      [
        "-Dgpl=enabled"
        "-Dfaad=disabled"
        "-Dresindvd=disabled"
        "-Dmpeg2enc=disabled"
        "-Dmplex=disabled"
      ]
    else
      [
        "-Ddts=disabled"
        "-Dfaad=disabled"
        "-Diqa=disabled"
        "-Dmpeg2enc=disabled"
        "-Dmplex=disabled"
        "-Dresindvd=disabled"
        "-Dx265=disabled"
      ]
  );

  postPatch = ''
    patchShebangs \
      scripts/extract-release-date-from-doap-file.py
  '';

  hardeningDisable = [ "format" ];

  preFixup = ''
    moveToOutput "lib/gstreamer-1.0/pkgconfig" "$dev"
  '';

  meta = {
    description = "GStreamer Bad Plugins";
    homepage = "https://gstreamer.freedesktop.org";
    license = if enableGplPlugins then lib.licenses.gpl2Plus else lib.licenses.lgpl2Plus;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
