{
  lib,
  stdenv,
  fetchurl,
  fetchpatch2,
  pkg-config,
  libsndfile,
  libtool,
  makeWrapper,
  perlPackages,
  libxtst,
  libxi,
  libx11,
  libsm,
  libice,
  libcap,
  alsa-lib,
  glib,
  dconf,
  libasyncns,
  dbus,
  udev,
  udevCheckHook,
  openssl,
  fftw,
  soxr,
  speexdsp,
  systemd,
  webrtc-audio-processing,
  check,
  meson,
  ninja,
  m4,
  bluez,
  sbc,
  libjack2,
  lirc,

  x11Support ? false,

  useSystemd ? lib.meta.availableOn stdenv.hostPlatform systemd,

  # Whether to build the OSS wrapper ("padsp").
  ossWrapper ? true,

  airtunesSupport ? false,

  bluetoothSupport ? stdenv.hostPlatform.isLinux,

  jackSupport ? !libOnly,

  lircSupport ? !libOnly,

  alsaSupport ? stdenv.hostPlatform.isLinux,
  udevSupport ? stdenv.hostPlatform.isLinux,

  # Whether to build only the library.
  libOnly ? false,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "${lib.optionalString libOnly "lib"}pulseaudio";
  version = "17.0";

  src = fetchurl {
    url = "https://freedesktop.org/software/pulseaudio/releases/pulseaudio-${finalAttrs.version}.tar.xz";
    hash = "sha256-BTeU1mcaPjl9hJ5HioC4KmPLnYyilr01tzMXu1zrh7U=";
  };

  patches = [
    # Install sysconfdir files inside of the nix store,
    # but use a conventional runtime sysconfdir outside the store
    ./add-option-for-installation-sysconfdir.patch

    # Fix crashes with some UCM devices
    # See https://gitlab.archlinux.org/archlinux/packaging/packages/pulseaudio/-/issues/4
    (fetchpatch2 {
      name = "alsa-ucm-Check-UCM-verb-before-working-with-device-status.patch";
      url = "https://gitlab.freedesktop.org/pulseaudio/pulseaudio/-/commit/f5cacd94abcc47003bd88ad7ca1450de649ffb15.patch";
      hash = "sha256-WyEqCitrqic2n5nNHeVS10vvGy5IzwObPPXftZKy/A8=";
    })
    (fetchpatch2 {
      name = "alsa-ucm-Replace-port-device-UCM-context-assertion-with-an-error.patch";
      url = "https://gitlab.freedesktop.org/pulseaudio/pulseaudio/-/commit/ed3d4f0837f670e5e5afb1afa5bcfc8ff05d3407.patch";
      hash = "sha256-fMJ3EYq56sHx+zTrG6osvI/QgnhqLvWiifZxrRLMvns=";
    })
  ];

  postPatch = ''
    # Fails in LXC containers where not all cores are enabled, where this setaffinity call will return EINVAL
    sed -i "/fail_unless(pthread_setaffinity_np/d" src/tests/once-test.c
  '';

  outputs = [
    "out"
    "dev"
  ];

  nativeBuildInputs = [
    pkg-config
    meson
    meson.configurePhaseHook
    ninja
    makeWrapper
    perlPackages.perl
    perlPackages.XMLParser
    m4
    udevCheckHook
  ]
  ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [ glib ];

  propagatedBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ libcap ];

  buildInputs = [
    libtool
    libsndfile
    soxr
    speexdsp
    fftw.float
    check
  ]
  ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
    glib
    dbus
  ]
  ++ lib.optionals (!libOnly) (
    [
      libasyncns
      webrtc-audio-processing
    ]
    ++ lib.optionals x11Support [
      libice
      libsm
      libx11
      libxi
      libxtst
    ]
    ++ lib.optional useSystemd systemd
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      alsa-lib
      udev
    ]
    ++ lib.optional airtunesSupport openssl
    ++ lib.optionals bluetoothSupport [
      bluez
      sbc
    ]
    ++ lib.optional jackSupport libjack2
    ++ lib.optional lircSupport lirc
  );

  env =
    lib.optionalAttrs (stdenv.cc.bintools.isLLVM && lib.versionAtLeast stdenv.cc.bintools.version "17")
      {
        # https://gitlab.freedesktop.org/pulseaudio/pulseaudio/-/issues/3848
        NIX_LDFLAGS = "--undefined-version";
      };

  mesonEntries = {
    alsa = if (!libOnly && alsaSupport) then "enabled" else "disabled";
    asyncns = if (!libOnly) then "enabled" else "disabled";
    avahi = "disabled";
    bluez5 = if (!libOnly && bluetoothSupport) then "enabled" else "disabled";
    bluez5-gstreamer = "disabled";
    database = "simple";
    doxygen = false;
    elogind = "disabled";
    # gsettings does not support cross-compilation
    gsettings =
      if (stdenv.hostPlatform.isLinux && (stdenv.buildPlatform == stdenv.hostPlatform)) then
        "enabled"
      else
        "disabled";
    gstreamer = "disabled";
    gtk = "disabled";
    jack = if (!libOnly && jackSupport) then "enabled" else "disabled";
    lirc = if (!libOnly && lircSupport) then "enabled" else "disabled";
    openssl = if airtunesSupport then "enabled" else "disabled";
    orc = "disabled";
    systemd = if (useSystemd && !libOnly) then "enabled" else "disabled";
    tcpwrap = "disabled";
    udev = if (!libOnly && udevSupport) then "enabled" else "disabled";
    valgrind = "disabled";
    webrtc-aec = if (!libOnly) then "enabled" else "disabled";
    x11 = if x11Support then "enabled" else "disabled";

    localstatedir = "/var";
    sysconfdir = "/etc";
    sysconfdir_install = "${placeholder "out"}/etc";
    udevrulesdir = "${placeholder "out"}/lib/udev/rules.d";

    ${if stdenv.hostPlatform.isLinux && useSystemd then "systemduserunitdir" else null} =
      "${placeholder "out"}/lib/systemd/user";
  }
  // lib.optionalAttrs stdenv.hostPlatform.isDarwin {
    consolekit = "disabled";
    dbus = "disabled";
    glib = "disabled";
    oss-output = "disabled";
  };

  mesonFlags = [
    # pulseaudio complains if its binary is moved after installation;
    # this is needed so that wrapGApp can operate *without*
    # renaming the unwrapped binaries (see below)
    "--bindir=${placeholder "out"}/.bin-unwrapped"
  ];

  preCheck = ''
    export HOME=$(mktemp -d)
  '';

  postInstall =
    lib.optionalString libOnly ''
      find $out/share -maxdepth 1 -mindepth 1 ! -name "vala" -prune -exec rm -r {} \;
      find $out/share/vala -maxdepth 1 -mindepth 1 ! -name "vapi" -prune -exec rm -r {} \;
      rm -r $out/{.bin-unwrapped,etc,lib/pulse-*}
    ''
    + ''
      moveToOutput lib/cmake "$dev"
      rm -f $out/.bin-unwrapped/qpaeq # this is packaged by the "qpaeq" package now, because of missing deps

      cp config.h $dev/include/pulse
    '';

  preFixup =
    lib.optionalString (stdenv.hostPlatform.isLinux && (stdenv.hostPlatform == stdenv.buildPlatform)) ''
      wrapProgram $out/libexec/pulse/gsettings-helper \
       --prefix XDG_DATA_DIRS : "$out/share/gsettings-schemas/${finalAttrs.pname}-${finalAttrs.version}" \
       --prefix GIO_EXTRA_MODULES : "${lib.getLib dconf}/lib/gio/modules"
    ''
    # put symlinks to binaries in `$prefix/bin`;
    # when pulseaudio is looking for its own binary (it does!),
    # it will be happy to find it in its original installation location
    + lib.optionalString (!libOnly) ''
      mkdir -p $out/bin
      ln -st $out/bin $out/.bin-unwrapped/*

      # Ensure that service files use the wrapped binaries.
      find "$out" -name "*.service" | while read f; do
          substituteInPlace "$f" --replace "$out/.bin-unwrapped/" "$out/bin/"
      done
    '';

  meta = {
    description = "Sound server for POSIX and Win32 systems";
    homepage = "http://www.pulseaudio.org/";
    license = lib.licenses.lgpl2Plus;
    platforms = lib.platforms.unix;

    # https://gitlab.freedesktop.org/pulseaudio/pulseaudio/-/issues/1089
    badPlatforms = [ lib.systems.inspect.platformPatterns.isStatic ];

    longDescription = ''
      PulseAudio is a sound server for POSIX and Win32 systems.  A
      sound server is basically a proxy for your sound applications.
      It allows you to do advanced operations on your sound data as it
      passes between your application and your hardware.  Things like
      transferring the audio to a different machine, changing the
      sample format or channel count and mixing several sounds into
      one are easily achieved using a sound server.
    '';
  };
})
