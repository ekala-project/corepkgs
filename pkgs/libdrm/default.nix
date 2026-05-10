{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  meson,
  ninja,
  libpthread-stubs,
  libpciaccess,
  python3Packages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libdrm";
  version = "2.4.131";

  src = fetchurl {
    url = "https://dri.freedesktop.org/libdrm/libdrm-${finalAttrs.version}.tar.xz";
    hash = "sha256-RbqZg7UciWQGo9ZU3oHTE7lTt25jkeJ5cHPVQ8X2F9U=";
  };

  outputs = [
    "out"
    "dev"
    "bin"
  ];

  nativeBuildInputs = [
    pkg-config
    meson
    meson.configurePhaseHook
    ninja
    python3Packages.docutils # Provides rst2man for documentation
  ];

  buildInputs = [
    libpthread-stubs
    libpciaccess
  ];

  mesonFlags = [
    "-Dinstall-test-programs=true"
    "-Dcairo-tests=disabled"
    (lib.mesonEnable "intel" true)
    (lib.mesonEnable "omap" stdenv.hostPlatform.isLinux)
    (lib.mesonEnable "valgrind" false) # Disable valgrind support for simplicity
  ]
  ++ lib.optionals stdenv.hostPlatform.isAarch [
    "-Dtegra=enabled"
  ]
  ++ lib.optionals (!stdenv.hostPlatform.isLinux) [
    "-Detnaviv=disabled"
  ];

  meta = {
    homepage = "https://gitlab.freedesktop.org/mesa/drm";
    downloadPage = "https://dri.freedesktop.org/libdrm/";
    description = "Direct Rendering Manager library and headers";
    longDescription = ''
      A userspace library for accessing the DRM (Direct Rendering Manager) on
      Linux, BSD and other operating systems that support the ioctl interface.
      The library provides wrapper functions for the ioctls to avoid exposing
      the kernel interface directly, and for chipsets with drm memory manager,
      support for tracking relocations and buffers.
      New functionality in the kernel DRM drivers typically requires a new
      libdrm, but a new libdrm will always work with an older kernel.

      libdrm is a low-level library, typically used by graphics drivers such as
      the Mesa drivers, the X drivers, libva and similar projects.
    '';
    license = lib.licenses.mit;
    platforms = lib.platforms.linux ++ lib.platforms.freebsd ++ lib.platforms.openbsd;
  };
})
