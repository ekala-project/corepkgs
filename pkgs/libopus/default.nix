{
  lib,
  stdenv,
  fetchurl,
  meson,
  python3,
  ninja,
  fixedPoint ? false,
  withCustomModes ? true,
  withIntrinsics ? stdenv.hostPlatform.isAarch || stdenv.hostPlatform.isx86,
  withAsm ? false,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libopus";
  version = "1.6.1";

  src = fetchurl {
    url = "https://downloads.xiph.org/releases/opus/opus-${finalAttrs.version}.tar.gz";
    hash = "sha256-b/y1kyB76SWE3xWzJGbtZLvsmRCfAHyCIF8BlFckEaE=";
  };

  postPatch = ''
    patchShebangs meson/
  '';

  outputs = [
    "out"
    "dev"
  ];

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    python3
    ninja
  ];

  mesonFlags = [
    (lib.mesonBool "fixed-point" fixedPoint)
    (lib.mesonBool "custom-modes" withCustomModes)
    (lib.mesonEnable "intrinsics" withIntrinsics)
    (lib.mesonEnable "rtcd" (withIntrinsics || withAsm))
    (lib.mesonEnable "asm" withAsm)
    (lib.mesonEnable "docs" false)
  ];

  doCheck = !stdenv.hostPlatform.isi686 && !stdenv.hostPlatform.isAarch32;

  meta = {
    description = "Open, royalty-free, highly versatile audio codec";
    homepage = "https://opus-codec.org/";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.all;
  };
})
