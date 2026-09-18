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
  libaom,
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
    libaom
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

  mesonFeatures = {
    auto_features = "auto";
    examples = false;
    glib_debug = false;
    doc = false;

    amfcodec = false;
    androidmedia = false;
    avtp = false;
    cuda-nvmm = false;
    directshow = false;
    qt6d3d11 = false;
    dts = false;
    zbar = false;
    faac = false;
    iqa = false;
    lcevcencoder = false;
    magicleap = false;
    msdk = false;
    musepack = false;
    nvcomp = false;
    nvdswrapper = false;
    openni2 = false;
    opensles = false;
    svthevcenc = false;
    svtjpegxs = false;
    teletext = false;
    tinyalsa = false;
    voamrwbenc = false;
    vulkan = false;
    wasapi = false;
    wasapi2 = false;
    wpe = false;
    wpe2 = false;
    gs = false;
    onnx = false;
    openaptx = false;
    opencv = false;
    aja = false;
    microdns = false;
    bluez = bluezSupport;
    openh264 = false;
    directfb = false;
    lcevcdecoder = false;
    ldac = false;
    webrtcdsp = webrtcAudioProcessingSupport;
    isac = webrtcAudioProcessingSupport;
    # Disabled deps not yet in core-pkgs
    flite = false;
    gsm = false;
    dc1394 = false;
    neon = false;
    openal = false;
    openexr = false;
    openmpt = false;
    rtmp2 = false;
    sbc = false;
    soundtouch = false;
    spandsp = false;
    srtp = false;
    wildmidi = false;
    fluidsynth = false;
    gme = false;
    voaacenc = false;
    zxing = false;
    sctp = false;
    bs2b = false;
    modplug = false;
    chromaprint = false;
    fdkaac = false;
    ladspa = false;
    ladspa-rdf = false;
    lv2 = false;
    rtmp = false;
    lc3 = false;
    assrender = libass != null;
    webrtc = false;
    gtk3 = false;
    rsvg = false;
    curl-ssh2 = false;
    shm = false;
    dtls = false;
    mpeghdec = false;
    tflite = false;
    gpl = enableGplPlugins;
    faad = false;
    resindvd = false;
    mpeg2enc = false;
    mplex = false;
    nvcodec = stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isx86;
    va = stdenv.hostPlatform.isLinux && gst-plugins-base.waylandEnabled;
    kms = !stdenv.hostPlatform.isDarwin;
    dvb = !stdenv.hostPlatform.isDarwin;
    fbdev = !stdenv.hostPlatform.isDarwin;
    uvcgadget = !stdenv.hostPlatform.isDarwin;
    uvch264 = !stdenv.hostPlatform.isDarwin;
    v4l2codecs = !stdenv.hostPlatform.isDarwin;
    qsv =
      stdenv.hostPlatform.isLinux && stdenv.hostPlatform.isx86_64 && gst-plugins-base.waylandEnabled;
    gl = gst-plugins-base.glEnabled;
    applemedia = gst-plugins-base.glEnabled;
    wayland = gst-plugins-base.waylandEnabled;
    x265 = enableGplPlugins;
  };

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
