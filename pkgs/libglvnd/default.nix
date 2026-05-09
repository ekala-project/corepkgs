{
  lib,
  stdenv,
  fetchFromGitLab,
  fetchpatch,
  autoreconfHook,
  pkg-config,
  python3,
  libx11,
  libxext,
  xorgproto,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libglvnd";
  version = "1.7.0";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "glvnd";
    repo = "libglvnd";
    rev = "v${finalAttrs.version}";
    hash = "sha256-2U9JtpGyP4lbxtVJeP5GUgh5XthloPvFIw28+nldYx8=";
  };

  patches = [
    # Enable 64-bit file APIs on 32-bit systems:
    #   https://gitlab.freedesktop.org/glvnd/libglvnd/-/merge_requests/288
    (fetchpatch {
      name = "large-file.patch";
      url = "https://gitlab.freedesktop.org/glvnd/libglvnd/-/commit/956d2d3f531841cabfeddd940be4c48b00c226b4.patch";
      hash = "sha256-Y6YCzd/jZ1VZP9bFlHkHjzSwShXeA7iJWdyfxpgT2l0=";
    })
  ];

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    python3
  ];

  buildInputs = [
    libx11
    libxext
    xorgproto
  ];

  env.NIX_CFLAGS_COMPILE = toString (
    [
      "-UDEFAULT_EGL_VENDOR_CONFIG_DIRS"
      # FHS paths for vendor files
      "-DDEFAULT_EGL_VENDOR_CONFIG_DIRS=\"/run/opengl-driver/share/glvnd/egl_vendor.d:/etc/glvnd/egl_vendor.d:/usr/share/glvnd/egl_vendor.d\""
      "-Wno-error=array-bounds"
    ]
    ++ lib.optionals stdenv.cc.isClang [
      "-Wno-error"
      "-Wno-int-conversion"
    ]
  );

  configureFlags = [ ];

  outputs = [
    "out"
    "dev"
  ];

  # Provide driverLink passthru for compatibility
  passthru = {
    driverLink = "/run/opengl-driver";
  };

  meta = {
    description = "GL Vendor-Neutral Dispatch library";
    longDescription = ''
      libglvnd is a vendor-neutral dispatch layer for arbitrating OpenGL API
      calls between multiple vendors. It allows multiple drivers from different
      vendors to coexist on the same filesystem, and determines which vendor to
      dispatch each API call to at runtime.
      Both GLX and EGL are supported, in any combination with OpenGL and OpenGL ES.
    '';
    homepage = "https://gitlab.freedesktop.org/glvnd/libglvnd";
    changelog = "https://gitlab.freedesktop.org/glvnd/libglvnd/-/tags/v${finalAttrs.version}";
    license = with lib.licenses; [
      mit
      bsd1
      bsd3
      gpl3Only
      asl20
    ];
    platforms = lib.platforms.unix;
  };
})
