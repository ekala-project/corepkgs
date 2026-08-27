{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  python3,
  libpthread-stubs,
  libxau,
  libxdmcp,
  xcb-proto,
  windows,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxcb";
  version = "1.17.0";

  outputs = [
    "out"
    "dev"
    "man"
    "doc"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxcb";
    tag = "libxcb-${finalAttrs.version}";
    hash = "sha256-obu3+tLMCjAmWsW+/7y7lZKTDniLtjVQwvdGJi36e4c=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    python3
    util-macros
  ];

  buildInputs = [
    libpthread-stubs
    libxau
    libxdmcp
    xcb-proto
  ];

  # $dev/include/xcb/xcb.h includes pthread.h
  propagatedBuildInputs = lib.optional stdenv.hostPlatform.isMinGW windows.pthreads;

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  env = lib.optionalAttrs stdenv.hostPlatform.isMinGW {
    NIX_CFLAGS_COMPILE = toString [ "-Wno-incompatible-pointer-types" ];
  };

  meta = {
    description = "C interface to the X Window System protocol";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxcb";
    # gitlab wrongly says X11 Distribute Modifications
    license = lib.licenses.x11;
    pkgConfigModules = [
      "xcb"
      "xcb-composite"
      "xcb-damage"
      "xcb-dpms"
      "xcb-dri2"
      "xcb-dri3"
      "xcb-glx"
      "xcb-present"
      "xcb-randr"
      "xcb-record"
      "xcb-render"
      "xcb-res"
      "xcb-screensaver"
      "xcb-shape"
      "xcb-shm"
      "xcb-sync"
      "xcb-xf86dri"
      "xcb-xfixes"
      "xcb-xinerama"
      "xcb-xinput"
      "xcb-xkb"
      "xcb-xtest"
      "xcb-xv"
      "xcb-xvmc"
    ];
    platforms = lib.platforms.unix ++ lib.platforms.windows;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
