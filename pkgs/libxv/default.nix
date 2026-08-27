{
  lib,
  stdenv,
  fetchFromGitLab,
  util-macros,
  autoreconfHook,
  pkg-config,
  xorgproto,
  libx11,
  libxext,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxv";
  version = "1.0.13";

  outputs = [
    "out"
    "dev"
    "devdoc"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxv";
    tag = "libXv-${finalAttrs.version}";
    hash = "sha256-NzTrrAXE3cHwYUfX1xmDwfXLYgKj9VdCtUg6GB3Oflw=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
  ];

  buildInputs = [
    xorgproto
    libx11
    libxext
  ];

  configureFlags = lib.optional (
    stdenv.hostPlatform != stdenv.buildPlatform
  ) "--enable-malloc0returnsnull";

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "Xlib-based library for the X Video (Xv) extension to the X Window System";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxv";
    license = with lib.licenses; [
      hpnd
      hpndSellVariant
    ];
    pkgConfigModules = [ "xv" ];
    platforms = lib.platforms.unix;
  };
})
