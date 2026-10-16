{
  version,
  src-hash,
  minimal ? false,
  ...
}:

{
  stdenv,
  lib,
  fetchFromGitHub,
  meson,
  pkg-config,
  ninja,
  wayland-scanner,
  libdrm,
  libx11,
  libxcb,
  libxext,
  wayland,
  libffi,
  libGL ? null,
  mesa ? null,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libva";
  extensions = lib.optionals minimal [ "minimal" ];
  inherit version;

  src = fetchFromGitHub {
    owner = "intel";
    repo = "libva";
    rev = finalAttrs.version;
    sha256 = src-hash;
  };

  outputs = [
    "dev"
    "out"
  ];

  depsBuildBuild = [ pkg-config ];

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    pkg-config
    ninja
  ]
  ++ lib.optional (!minimal) wayland-scanner;

  buildInputs = [
    libdrm
  ]
  ++ lib.optionals (!minimal) [
    libx11
    libxcb
    libxext
    wayland
    libffi
  ]
  ++ lib.optional (!minimal && libGL != null) libGL;

  mesonEntries = lib.optionalAttrs (stdenv.hostPlatform.isLinux && mesa != null) {
    driverdir = "${mesa.driverLink or "/run/opengl-driver"}/lib/dri:/usr/lib/dri:/usr/lib32/dri";
  };

  env =
    lib.optionalAttrs (stdenv.cc.bintools.isLLVM && lib.versionAtLeast stdenv.cc.bintools.version "17")
      {
        NIX_LDFLAGS = "--undefined-version";
      }
    // lib.optionalAttrs (stdenv.targetPlatform.useLLVM or false) {
      NIX_CFLAGS_COMPILE = "-DHAVE_SECURE_GETENV";
    };

  meta = {
    description = "Implementation for VA-API (Video Acceleration API)";
    homepage = "https://01.org/linuxmedia/vaapi";
    license = lib.licenses.mit;
    pkgConfigModules = [
      "libva"
      "libva-drm"
    ]
    ++ lib.optionals (!minimal) [
      "libva-glx"
      "libva-wayland"
      "libva-x11"
    ];
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "intel" finalAttrs.version;
  };
})
