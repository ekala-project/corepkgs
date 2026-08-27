{
  lib,
  stdenv,
  fetchFromGitLab,
  bash,
  dri-pkgconfig-stub,
  font-util,
  libdrm,
  libepoxy,
  libGL,
  libGLU,
  libgbm,
  libtirpc,
  libunwind,
  libx11,
  libxau,
  libxaw,
  libxcb,
  libxcvt,
  libxdmcp,
  libxext,
  libxfixes,
  libxfont_2,
  libxkbfile,
  libxmu,
  libxpm,
  libxrender,
  libxshmfence,
  libxt,
  mesa-gl-headers,
  meson,
  ninja,
  openssl,
  pixman,
  pkg-config,
  systemd,
  wayland,
  wayland-protocols,
  wayland-scanner,
  xkbcomp,
  xkeyboard-config,
  xorgproto,
  xtrans,
  zlib,
  defaultFontPath ? "",
  # LLVM's libunwind conflicts and does not provide the right symbols.
  withLibunwind ? !(stdenv.hostPlatform.useLLVM or false),
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "xwayland";
  version = "24.1.13";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "xorg";
    repo = "xserver";
    tag = "xwayland-${finalAttrs.version}";
    hash = "sha256-sxCifKzdkZDhiUB0C2a/CGtj9kn87IhUkIj3asc7l50=";
  };

  postPatch = ''
    substituteInPlace os/utils.c \
      --replace-fail '/bin/sh' '${lib.getExe' bash "sh"}'
  '';

  strictDeps = true;

  depsBuildBuild = [ pkg-config ];

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
    wayland-scanner
  ];

  buildInputs = [
    dri-pkgconfig-stub
    font-util
    libdrm
    libepoxy
    libGL
    libGLU
    libgbm
    libtirpc
    libx11
    libxau
    libxaw
    libxcb
    libxcvt
    libxdmcp
    libxext
    libxfixes
    libxfont_2
    libxkbfile
    libxmu
    libxpm
    libxrender
    libxshmfence
    libxt
    mesa-gl-headers
    openssl
    pixman
    systemd
    wayland
    wayland-protocols
    xkbcomp
    xorgproto
    xtrans
    zlib
    # TODO(corepkgs): port egl-wayland for the EGLStream backend
    # TODO(corepkgs): port libdecor for rootful window decorations
    # TODO(corepkgs): port libei for XTEST input emulation
  ]
  ++ lib.optionals withLibunwind [
    libunwind
  ];

  mesonFlags = [
    (lib.mesonBool "xcsecurity" true)
    (lib.mesonOption "default_font_path" defaultFontPath)
    (lib.mesonOption "xkb_bin_dir" "${xkbcomp}/bin")
    (lib.mesonOption "xkb_dir" "${xkeyboard-config}/share/X11/xkb")
    (lib.mesonOption "xkb_output_dir" "${placeholder "out"}/share/X11/xkb/compiled")
    (lib.mesonBool "libunwind" withLibunwind)
  ];

  meta = {
    description = "X server for interfacing X11 apps with the Wayland protocol";
    homepage = "https://gitlab.freedesktop.org/xorg/xserver";
    license = lib.licenses.mit;
    mainProgram = "Xwayland";
    platforms = lib.platforms.linux;
  };
})
