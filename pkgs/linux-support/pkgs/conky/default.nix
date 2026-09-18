{
  config,
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  pkg-config,
  cmake,

  # dependencies
  glib,
  libxfixes,
  libXinerama,
  catch2,
  gperf,

  # lib.optional features without extra dependencies
  mpdSupport ? true,
  ibmSupport ? true, # IBM/Lenovo notebooks

  # lib.optional features with extra dependencies

  docsSupport ? true,
  buildPackages,
  pandoc,
  python3,

  ncursesSupport ? true,
  ncurses ? null,
  x11Support ? true,
  freetype,
  libice,
  libx11,
  libxext,
  libxft,
  libsm,
  waylandSupport ? true,
  pango,
  wayland,
  wayland-protocols,
  wayland-scanner,
  xdamageSupport ? x11Support,
  libXdamage ? null,
  doubleBufferSupport ? x11Support,
  imlib2Support ? x11Support,
  imlib2 ? null,

  luaSupport ? true,
  lua ? null,
  luaImlib2Support ? luaSupport && imlib2Support,
  luaCairoSupport ? luaSupport && (x11Support || waylandSupport),
  cairo ? null,
  toluapp ? null,

  wirelessSupport ? true,
  wirelesstools ? null,
  nvidiaSupport ? false,
  libXNVCtrl ? null,
  pulseSupport ? config.pulseaudio or false,
  libpulseaudio ? null,

  curlSupport ? true,
  curl ? null,
  rssSupport ? curlSupport,
  journalSupport ? true,
  systemd ? null,
  libxml2 ? null,

  extrasSupport ? true,

  versionCheckHook,
  expat,
}:

assert docsSupport -> pandoc != null && python3 != null;

assert ncursesSupport -> ncurses != null;

assert xdamageSupport -> x11Support && libXdamage != null;
assert imlib2Support -> x11Support && imlib2 != null;
assert luaSupport -> lua != null;
assert luaImlib2Support -> luaSupport && imlib2Support && toluapp != null;
assert luaCairoSupport -> luaSupport && toluapp != null && cairo != null;
assert luaCairoSupport || luaImlib2Support -> lua.luaversion == "5.4";

assert wirelessSupport -> wirelesstools != null;
assert nvidiaSupport -> libXNVCtrl != null;
assert pulseSupport -> libpulseaudio != null;

assert curlSupport -> curl != null;
assert rssSupport -> curlSupport && libxml2 != null;
assert journalSupport -> systemd != null;

assert extrasSupport -> python3 != null;

stdenv.mkDerivation (finalAttrs: {
  pname = "conky";
  version = "1.22.2";

  src = fetchFromGitHub {
    owner = "brndnmtthws";
    repo = "conky";
    tag = "v${finalAttrs.version}";
    hash = "sha256-tMnfdW1sbZkt8v6DITM2R0ZwyN+xs7VLGZDityYt38Q=";
  };

  # pkg-config doesn't detect wayland-scanner in cross-compilation for some reason
  postPatch = ''
    substituteInPlace cmake/ConkyPlatformChecks.cmake \
      --replace-fail "pkg_get_variable(Wayland_SCANNER wayland-scanner wayland_scanner)" "set(Wayland_SCANNER ${lib.getExe buildPackages.wayland-scanner})"
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
    gperf
  ]
  ++ lib.optional docsSupport pandoc
  ++ lib.optional (docsSupport || extrasSupport) (
    # Use buildPackages to work around https://github.com/NixOS/nixpkgs/issues/305858
    buildPackages.python3.withPackages (ps: [
      ps.jinja2
      ps.pyyaml
    ])
  )
  ++ lib.optional luaImlib2Support toluapp
  ++ lib.optional luaCairoSupport toluapp;

  buildInputs = [
    glib
    libXinerama
  ]
  ++ lib.optional ncursesSupport ncurses
  ++ lib.optionals x11Support [
    freetype
    libxfixes
    libice
    libx11
    libxext
    libxft
    libxfixes
    libsm
    expat
  ]
  ++ lib.optionals waylandSupport [
    pango
    wayland
    wayland-protocols
  ]
  ++ lib.optional xdamageSupport libXdamage
  ++ lib.optional imlib2Support imlib2
  ++ lib.optional luaSupport lua
  ++ lib.optional luaImlib2Support imlib2
  ++ lib.optional luaCairoSupport cairo
  ++ lib.optional wirelessSupport wirelesstools
  ++ lib.optional curlSupport curl
  ++ lib.optional rssSupport libxml2
  ++ lib.optional nvidiaSupport libXNVCtrl
  ++ lib.optional pulseSupport libpulseaudio
  ++ lib.optional journalSupport systemd;

  cmakeEntries = {
    REPRODUCIBLE_BUILD = true;
    RELEASE = true;
    BUILD_TESTING = finalAttrs.finalPackage.doCheck;
    BUILD_EXTRAS = extrasSupport;
    BUILD_DOCS = docsSupport;
    BUILD_CURL = curlSupport;
    BUILD_IBM = ibmSupport;
    BUILD_IMLIB2 = imlib2Support;
    BUILD_LUA_CAIRO = luaCairoSupport;
    BUILD_LUA_IMLIB2 = luaImlib2Support;
    BUILD_MPD = mpdSupport;
    BUILD_NCURSES = ncursesSupport;
    BUILD_RSS = rssSupport;
    BUILD_X11 = x11Support;
    BUILD_WAYLAND = waylandSupport;
    BUILD_XDAMAGE = xdamageSupport;
    BUILD_XDBE = doubleBufferSupport;
    BUILD_WLAN = wirelessSupport;
    BUILD_NVIDIA = nvidiaSupport;
    BUILD_PULSEAUDIO = pulseSupport;
    BUILD_JOURNAL = journalSupport;
    CMAKE_INSTALL_DATAROOTDIR = "${placeholder "out"}/share";
  };

  doCheck = true;

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  meta = {
    homepage = "https://conky.cc";
    changelog = "https://github.com/brndnmtthws/conky/releases/tag/${finalAttrs.src.tag}";
    description = "Advanced, highly configurable system monitor based on torsmo";
    mainProgram = "conky";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
})
