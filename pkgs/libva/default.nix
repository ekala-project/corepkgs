{
  stdenv,
  lib,
  fetchFromGitHub,
  meson,
  pkg-config,
  ninja,
  wayland-scanner,
  libdrm,
  minimal ? false,
  libx11,
  libxcb,
  libxext,
  wayland,
  libffi,
  libGL ? null,
  mesa ? null,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libva" + lib.optionalString minimal "-minimal";
  version = "2.23.0";

  src = fetchFromGitHub {
    owner = "intel";
    repo = "libva";
    rev = finalAttrs.version;
    sha256 = "sha256-ePtzZPzBnkhV0cV3Nw/pgOnKnzDkk7U2Svzo0e1YMbc=";
  };

  outputs = [
    "dev"
    "out"
  ];

  depsBuildBuild = [ pkg-config ];

  nativeBuildInputs =
    [
      meson
      meson.configurePhaseHook
      pkg-config
      ninja
    ]
    ++ lib.optional (!minimal) wayland-scanner;

  buildInputs =
    [
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

  mesonFlags = lib.optionals (stdenv.hostPlatform.isLinux && mesa != null) [
    "-Ddriverdir=${mesa.driverLink or "/run/opengl-driver"}/lib/dri:/usr/lib/dri:/usr/lib32/dri"
  ];

  env =
    lib.optionalAttrs
      (stdenv.cc.bintools.isLLVM && lib.versionAtLeast stdenv.cc.bintools.version "17")
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
    maintainers = [ ];
    pkgConfigModules =
      [
        "libva"
        "libva-drm"
      ]
      ++ lib.optionals (!minimal) [
        "libva-glx"
        "libva-wayland"
        "libva-x11"
      ];
    platforms = lib.platforms.unix;
  };
})
