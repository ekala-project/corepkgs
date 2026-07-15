{
  lib,
  stdenv,
  fetchurl,
  cmake,
  nasm,

  numaSupport ? (
    stdenv.hostPlatform.isLinux && (stdenv.hostPlatform.isx86 || stdenv.hostPlatform.isAarch64)
  ),
  numactl,

  multibitdepthSupport ? stdenv.hostPlatform.is64bit,

  cliSupport ? true,
  custatsSupport ? false,
  debugSupport ? false,
  ppaSupport ? false,
  unittestsSupport ? stdenv.hostPlatform.isx86_64,
  vtuneSupport ? false,
  werrorSupport ? false,
  neonSupport ? false,
}:

let
  isCross = stdenv.buildPlatform != stdenv.hostPlatform;
in

stdenv.mkDerivation (finalAttrs: {
  pname = "x265";
  version = "4.2";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "https://bitbucket.org/multicoreware/x265_git/downloads/x265_${finalAttrs.version}.tar.gz";
    hash = "sha256-QLHqBFPgMJ8OupNODd9TP49ilZZmeeiJTo8cHI1eEhA=";
  };

  sourceRoot = "x265_${finalAttrs.version}/source";

  postPatch = ''
    substituteInPlace cmake/Version.cmake \
      --replace-fail "unknown" "${finalAttrs.version}" \
      --replace-fail "0.0" "${finalAttrs.version}"
  ''
  + lib.optionalString stdenv.hostPlatform.isMinGW ''
    echo 'set(X265_LATEST_TAG "${finalAttrs.version}")' >> ./cmake/Version.cmake
  '';

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    nasm
  ]
  ++ lib.optionals numaSupport [ numactl ];

  cmakeFlags = [
    (lib.cmakeBool "ENABLE_ALPHA" true)
    (lib.cmakeBool "ENABLE_MULTIVIEW" true)
    (lib.cmakeBool "ENABLE_SCC_EXT" true)
    "-Wno-dev"
    (lib.cmakeBool "DETAILED_CU_STATS" custatsSupport)
    (lib.cmakeBool "CHECKED_BUILD" debugSupport)
    (lib.cmakeBool "ENABLE_PPA" ppaSupport)
    (lib.cmakeBool "ENABLE_VTUNE" vtuneSupport)
    (lib.cmakeBool "WARNINGS_AS_ERRORS" werrorSupport)
  ]
  ++ lib.optionals stdenv.hostPlatform.isPower [
    (lib.cmakeBool "ENABLE_ALTIVEC" false)
    (lib.cmakeBool "CPU_POWER8" (stdenv.hostPlatform.isPower64 && stdenv.hostPlatform.isLittleEndian))
  ]
  ++ lib.optionals (neonSupport && stdenv.hostPlatform.isAarch32) [
    (lib.cmakeBool "ENABLE_NEON" true)
    (lib.cmakeBool "CPU_HAS_NEON" true)
    (lib.cmakeBool "ENABLE_ASSEMBLY" true)
  ];

  cmakeStaticLibFlags = [
    (lib.cmakeBool "HIGH_BIT_DEPTH" true)
    (lib.cmakeBool "ENABLE_CLI" false)
    (lib.cmakeBool "ENABLE_SHARED" false)
    (lib.cmakeBool "EXPORT_C_API" false)
  ]
  ++ lib.optionals isCross [
    (lib.cmakeBool "CROSS_COMPILE_ARM" stdenv.hostPlatform.isAarch32)
    (lib.cmakeBool "CROSS_COMPILE_ARM64" stdenv.hostPlatform.isAarch64)
  ];

  preConfigure =
    lib.optionalString multibitdepthSupport ''
      cmake -B build-10bits "''${cmakeFlags[@]}" "''${cmakeFlagsArray[@]}" "''${cmakeStaticLibFlags[@]}"
      cmake -B build-12bits "''${cmakeFlags[@]}" "''${cmakeFlagsArray[@]}" "''${cmakeStaticLibFlags[@]}" ${lib.cmakeBool "MAIN12" true}
      cmakeFlagsArray+=(
        ${lib.cmakeFeature "EXTRA_LIB" "\"x265-10.a;x265-12.a\""}
        ${lib.cmakeFeature "EXTRA_LINK_FLAGS" "-L."}
        ${lib.cmakeBool "LINKED_10BIT" true}
        ${lib.cmakeBool "LINKED_12BIT" true}
      )
    ''
    + ''
      cmakeFlagsArray+=(
        ${lib.cmakeBool "GIT_ARCHETYPE" true}
        ${lib.cmakeBool "ENABLE_SHARED" (!stdenv.hostPlatform.isStatic)}
        ${lib.cmakeBool "HIGH_BIT_DEPTH" false}
        ${lib.cmakeBool "ENABLE_HDR10_PLUS" true}
        ${lib.cmakeBool "ENABLE_CLI" cliSupport}
        ${lib.cmakeBool "ENABLE_TESTS" unittestsSupport}
      )
    '';

  preBuild = lib.optionalString multibitdepthSupport ''
    make -C ../build-10bits -j $NIX_BUILD_CORES
    make -C ../build-12bits -j $NIX_BUILD_CORES
    ln -s ../build-10bits/libx265.a ./libx265-10.a
    ln -s ../build-12bits/libx265.a ./libx265-12.a
  '';

  doCheck = unittestsSupport;

  checkPhase = ''
    runHook preCheck

    ./test/TestBench

    runHook postCheck
  '';

  postInstall = ''
    rm -f ${placeholder "out"}/lib/*.a
  ''
  + lib.optionalString stdenv.hostPlatform.isMinGW ''
    ln -s $out/bin/*.dll $out/lib
  '';

  __structuredAttrs = true;

  meta = {
    description = "Library for encoding H.265/HEVC video streams";
    mainProgram = "x265";
    homepage = "https://www.x265.org";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.all;
  };
})
