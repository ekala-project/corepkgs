{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  writableTmpDirAsHomeHook,
  docbook-xsl-nons,
  libxslt,
  pkg-config,
  alsa-lib,
  ffmpeg,
  fuse,
  glib,
  openssl,
  pcre2,
  zlib,
  libx11,
  libxcursor,
  libxdmcp,
  libxext,
  libxi,
  libxinerama,
  libxrandr,
  libxrender,
  libxtst,
  libxv,
  libxkbcommon,
  libxkbfile,
  wayland,
  wayland-scanner,
  icu,
  libunwind,
  cairo,
  libcbor,
  libfido2,
  libusb1,
  cups,
  pcsclite,
  sdl3,
  systemd,
  libjpeg,
  libkrb5,
  libopus,
  makeWrapper,
  buildServer ? true,
  nocaps ? false,
  withWaylandSupport ? false,

  # tries to compile and run generate_argument_docbook.c
  withManPages ? stdenv.buildPlatform.canExecute stdenv.hostPlatform,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "freerdp";
  version = "3.30.0";

  src = fetchFromGitHub {
    owner = "FreeRDP";
    repo = "FreeRDP";
    tag = finalAttrs.version;
    hash = "sha256-Fy7TB7cRHXB86deb86eg05Cwf9SHU0C/Qnfj5Ylmjug=";
  };

  postPatch = ''
    # skip NIB file generation on darwin
    substituteInPlace "client/Mac/CMakeLists.txt" "client/Mac/cli/CMakeLists.txt" \
      --replace-fail "if(NOT IS_XCODE)" "if(FALSE)"

    substituteInPlace "libfreerdp/freerdp.pc.in" \
      --replace-fail "Requires:" "Requires: @WINPR_PKG_CONFIG_FILENAME@"
  ''
  + lib.optionalString (pcsclite != null) ''
    substituteInPlace "winpr/libwinpr/smartcard/smartcard_pcsc.c" \
      --replace-fail "libpcsclite.so" "${lib.getLib pcsclite}/lib/libpcsclite.so"
  ''
  + lib.optionalString nocaps ''
    substituteInPlace "libfreerdp/locale/keyboard_xkbfile.c" \
      --replace-fail "RDP_SCANCODE_CAPSLOCK" "RDP_SCANCODE_LCONTROL"
  '';

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    libxslt
    docbook-xsl-nons
    pkg-config
    wayland-scanner
    writableTmpDirAsHomeHook
    makeWrapper
  ];

  buildInputs = [
    cairo
    cups
    ffmpeg
    glib
    icu
    libcbor
    libfido2
    libx11
    libxcursor
    libxdmcp
    libxext
    libxi
    libxinerama
    libxrandr
    libxrender
    libxtst
    libxv
    libjpeg
    libkrb5
    libopus
    libunwind
    libusb1
    libxkbcommon
    libxkbfile
    openssl
    pcre2
    pcsclite
    sdl3
    zlib
    # TODO(corepkgs): Port openh264 for H.264 codec support
    # TODO(corepkgs): Port faad2 for AAC decoding support
    # TODO(corepkgs): Port pkcs11helper for PKCS#11 support
    # TODO(corepkgs): Port uriparser for URI parsing support
    # TODO(corepkgs): Port orc for optimized inner loops
    # TODO(corepkgs): Port cjson for JSON support
    # TODO(corepkgs): Port sdl3-ttf for SDL3 TTF rendering
    # TODO(corepkgs): Port sdl3-image for SDL3 image loading
    # TODO(corepkgs): Port libpulseaudio for PulseAudio support
    # TODO(corepkgs): Port libxdamage for X11 damage extension
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    alsa-lib
    fuse
    systemd
    wayland
    wayland-scanner
  ];

  # https://github.com/FreeRDP/FreeRDP/issues/8526#issuecomment-1357134746
  cmakeFlags = [
    "-Wno-dev"
    (lib.cmakeFeature "CMAKE_INSTALL_LIBDIR" "lib")
    (lib.cmakeFeature "DOCBOOKXSL_DIR" "${docbook-xsl-nons}/xml/xsl/docbook")
  ]
  ++ lib.mapAttrsToList lib.cmakeBool (
    {
      BUILD_TESTING = false; # false is recommended by upstream
      CHANNEL_RDPEWA = true;
      CHANNEL_RDPEWA_CLIENT = true;
      WITH_CAIRO = cairo != null;
      WITH_CUPS = cups != null;
      WITH_FAAC = false; # TODO(corepkgs): Port faac for AAC encoding
      WITH_FAAD2 = false; # TODO(corepkgs): Port faad2 for AAC decoding
      WITH_FUSE = stdenv.hostPlatform.isLinux && fuse != null;
      WITH_JPEG = libjpeg != null;
      WITH_KRB5 = libkrb5 != null;
      WITH_OPENH264 = false; # TODO(corepkgs): Port openh264
      WITH_OPUS = libopus != null;
      WITH_OSS = false;
      WITH_MANPAGES = withManPages;
      WITH_PCSC = pcsclite != null;
      WITH_PULSE = false; # TODO(corepkgs): Port libpulseaudio
      WITH_SERVER = buildServer;
      WITH_WEBVIEW = false; # avoid introducing webkit2gtk-4.0
      WITH_VAAPI = false; # false is recommended by upstream
    }
    // lib.filterAttrs (_name: value: value) {
      # Only select one
      WITH_X11 = !withWaylandSupport;
      WITH_WAYLAND = withWaylandSupport;
    }
  )
  ++ lib.optionals (!stdenv.buildPlatform.canExecute stdenv.hostPlatform) [
    (lib.cmakeBool "SDL_USE_COMPILED_RESOURCES" false)
  ];

  env.NIX_CFLAGS_COMPILE = toString (
    lib.optionals stdenv.hostPlatform.isDarwin [
      "-include AudioToolbox/AudioToolbox.h"
    ]
    ++ lib.optionals stdenv.cc.isClang [
      "-Wno-error=incompatible-function-pointer-types"
    ]
  );

  meta = {
    description = "Remote Desktop Protocol Client";
    longDescription = ''
      FreeRDP is a client-side implementation of the Remote Desktop Protocol (RDP)
      following the Microsoft Open Specifications.
    '';
    changelog = "https://github.com/FreeRDP/FreeRDP/releases/tag/${finalAttrs.src.tag}";
    homepage = "https://www.freerdp.com/";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
})
