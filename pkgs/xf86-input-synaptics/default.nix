{
  lib,
  stdenv,
  fetchFromGitLab,
  autoreconfHook,
  pkg-config,
  util-macros,
  xorg-server,
  xorgproto,
  libevdev,
  libx11,
  libxi,
  libxtst,
  testers,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "xf86-input-synaptics";
  version = "1.10.0";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "driver";
    repo = "xf86-input-synaptics";
    tag = "xf86-input-synaptics-${finalAttrs.version}";
    hash = "sha256-IHkUxphSV6JOlTzIgXGl5hWb6OphJ9Lyzp/YS2phVQs=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    util-macros
    xorg-server
  ];

  buildInputs = [
    xorg-server
    xorgproto
    libevdev
    libx11
    libxi
    libxtst
  ];

  configureFlags = [
    "--with-sdkdir=${placeholder "dev"}/include/xorg"
    "--with-xorg-conf-dir=${placeholder "out"}/share/X11/xorg.conf.d"
  ];

  passthru = {
    tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
  };

  meta = {
    description = "Synaptics touchpad driver for the Xorg X server";
    homepage = "https://gitlab.freedesktop.org/xorg/driver/xf86-input-synaptics";
    license = lib.licenses.mit;
    pkgConfigModules = [ "xorg-synaptics" ];
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
    platforms = lib.platforms.unix;
  };
})
