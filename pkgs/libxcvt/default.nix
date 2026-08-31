{
  lib,
  stdenv,
  fetchFromGitLab,
  pkg-config,
  meson,
  ninja,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libxcvt";
  version = "0.1.3";

  outputs = [
    "out"
    "include"
  ];

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    group = "xorg";
    owner = "lib";
    repo = "libxcvt";
    tag = "libxcvt-${finalAttrs.version}";
    hash = "sha256-zi33uydI/XCKk8PZuRlaHyXFOEX4FkAyzSgB19wXKjE=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
    meson
    meson.configurePhaseHook
    ninja
  ];

  meta = {
    description = "VESA CVT standard timing modeline generation library & utility";
    homepage = "https://gitlab.freedesktop.org/xorg/lib/libxcvt";
    license = with lib.licenses; [
      mit
      hpndSellVariant
    ];
    mainProgram = "cvt";
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "x.org" finalAttrs.version;
  };
})
