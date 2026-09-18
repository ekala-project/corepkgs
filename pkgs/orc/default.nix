{
  lib,
  stdenv,
  fetchurl,
  meson,
  ninja,
  pkg-config,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "orc";
  version = "0.4.42";

  outputs = [
    "out"
    "dev"
  ];
  outputBin = "dev";

  src = fetchurl {
    url = "https://gstreamer.freedesktop.org/src/orc/orc-${finalAttrs.version}.tar.xz";
    hash = "sha256-fskSq1mvPMl4dMRWpWqK4e7FIMOF7ER+ihArK9EiyQw=";
  };

  postPatch = lib.optionalString (stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isx86_64) ''
    sed -i '/memcpy_speed/d' testsuite/meson.build
  '';

  mesonFeatures = {
    examples = false;
    benchmarks = false;
    tests = finalAttrs.finalPackage.doCheck;
    hotdoc = false;
  };

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
  ];

  doCheck =
    !(
      stdenv.hostPlatform.isLinux
      && stdenv.hostPlatform.isAarch64
      && stdenv.cc.isGNU
      && lib.versionAtLeast stdenv.cc.version "12"
    );

  meta = {
    description = "Oil Runtime Compiler";
    homepage = "https://gstreamer.freedesktop.org/projects/orc.html";
    license = with lib.licenses; [
      bsd3
      bsd2
    ];
    platforms = lib.platforms.unix;
  };
})
