{
  lib,
  stdenv,
  fetchFromGitLab,
  autoreconfHook,
  pkg-config,
  util-macros,
  wrapWithXFileSearchPathHook,
  libx11,
  libxaw,
  libxmu,
  xorgproto,
  libxt,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "xload";
  version = "1.2.2";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "app";
    repo = "xload";
    tag = "xload-${finalAttrs.version}";
    hash = "sha256-FP1GrB0a6z6Gu6AQRTFbnp7iSush6XSoIklD74bNok4=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
    wrapWithXFileSearchPathHook
  ];

  buildInputs = [
    libx11
    libxaw
    libxmu
    xorgproto
    libxt
  ];

  installFlags = [ "appdefaultdir=$out/share/X11/app-defaults" ];

  meta = {
    identifiers.cpeParts.vendor = "x.org";
    description = "System load average display for X";
    longDescription = ''
      xload displays a periodically updating histogram of the system load average.
    '';
    homepage = "https://gitlab.freedesktop.org/xorg/app/xload";
    license = with lib.licenses; [
      x11
      mit
    ];
    mainProgram = "xload";
    platforms = lib.platforms.unix;
  };
})
