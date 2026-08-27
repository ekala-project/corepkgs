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
  libxi,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxtst";
  version = "1.2.5";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxtst";
    tag = "libXtst-${finalAttrs.version}";
    hash = "sha256-DzoCtyB6bUUnP9a/hjuJLOesaKg+sjM2lQY8s42HWC4=";
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
    libxi
  ];

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "Library for the XTEST and RECORD X11 extensions";
    longDescription = ''
      The XTEST extension is a minimal set of client and server extensions required to completely
      test the X11 server with no user intervention. This extension is not intended to support
      general journaling and playback of user actions.
      The RECORD extension supports the recording and reporting of all core X protocol and arbitrary
      X extension protocol.
    '';
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxtst";
    license = with lib.licenses; [
      mitOpenGroup
      hpndSellVariant
      hpndDoc
      x11
      hpndDocSell
    ];
    pkgConfigModules = [ "xtst" ];
    platforms = lib.platforms.unix;
  };
})
