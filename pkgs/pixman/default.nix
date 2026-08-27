{
  lib,
  stdenv,
  fetchFromGitLab,
  meson,
  ninja,
  pkg-config,
  libpng,

  testers,

  __flattenIncludeHackHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pixman";
  version = "0.46.4";

  src = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "pixman";
    repo = "pixman";
    tag = "pixman-${finalAttrs.version}";
    hash = "sha256-SiXzRtCuAkbg4LBFc3USTRwj9qsAtLyfzaDMed8h7Cc=";
  };

  # Raise test timeout, 120s can be slightly exceeded on slower hardware
  postPatch = ''
    substituteInPlace test/meson.build \
      --replace-fail 'timeout : 120' 'timeout : 240'
  '';

  separateDebugInfo = !stdenv.hostPlatform.isStatic;

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
    __flattenIncludeHackHook
  ];

  buildInputs = [ libpng ];

  # Default "enabled" value attempts to enable CPU features on all
  # architectures and requires used to disable them:
  #   https://gitlab.freedesktop.org/pixman/pixman/-/issues/88
  mesonAutoFeatures = "auto";
  # fix armv7 build
  mesonFlags = lib.optionals stdenv.hostPlatform.isAarch32 [
    "-Darm-simd=disabled"
    "-Dneon=disabled"
  ];

  preConfigure = ''
    # https://gitlab.freedesktop.org/pixman/pixman/-/issues/62
    export OMP_NUM_THREADS=$((NIX_BUILD_CORES > 184 ? 184 : NIX_BUILD_CORES))
  '';

  enableParallelBuilding = true;

  doCheck = !stdenv.hostPlatform.isDarwin;

  passthru = {
    tests = {
      pkg-config = testers.hasPkgConfigModules {
        package = finalAttrs.finalPackage;
      };
    };
  };

  meta = {
    homepage = "https://pixman.org";
    description = "Low-level library for pixel manipulation";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    pkgConfigModules = [ "pixman-1" ];
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "pixman" finalAttrs.version;
  };
})
