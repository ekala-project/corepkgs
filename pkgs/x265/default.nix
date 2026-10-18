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

  cmakeFlags = [ "-Wno-dev" ];

  cmakeEntries = {
    ENABLE_ALPHA = true;
    ENABLE_MULTIVIEW = true;
    ENABLE_SCC_EXT = true;
    DETAILED_CU_STATS = custatsSupport;
    CHECKED_BUILD = debugSupport;
    ENABLE_PPA = ppaSupport;
    ENABLE_VTUNE = vtuneSupport;
    WARNINGS_AS_ERRORS = werrorSupport;
    GIT_ARCHETYPE = true;
    ENABLE_SHARED = !stdenv.hostPlatform.isStatic;
    HIGH_BIT_DEPTH = false;
    ENABLE_HDR10_PLUS = true;
    ENABLE_CLI = cliSupport;
    ENABLE_TESTS = unittestsSupport;
  }
  // lib.optionalAttrs stdenv.hostPlatform.isPower {
    ENABLE_ALTIVEC = false;
    CPU_POWER8 = stdenv.hostPlatform.isPower64 && stdenv.hostPlatform.isLittleEndian;
  }
  // lib.optionalAttrs (neonSupport && stdenv.hostPlatform.isAarch32) {
    ENABLE_NEON = true;
    CPU_HAS_NEON = true;
    ENABLE_ASSEMBLY = true;
  };

  cmakeStaticLibFlags = [
    (lib.cmakeBool "HIGH_BIT_DEPTH" true)
    (lib.cmakeBool "ENABLE_CLI" false)
    (lib.cmakeBool "ENABLE_SHARED" false)
    (lib.cmakeBool "EXPORT_C_API" false)
    (lib.cmakeBool "ENABLE_TESTS" false)
  ]
  ++ lib.optionals isCross [
    (lib.cmakeBool "CROSS_COMPILE_ARM" stdenv.hostPlatform.isAarch32)
    (lib.cmakeBool "CROSS_COMPILE_ARM64" stdenv.hostPlatform.isAarch64)
  ];

  preConfigure = lib.optionalString multibitdepthSupport ''
    local entryFlags=()
    concatCMakeEntryFlagsTo entryFlags
    cmake -B build-10bits "''${cmakeFlags[@]}" "''${entryFlags[@]}" "''${cmakeStaticLibFlags[@]}"
    cmake -B build-12bits "''${cmakeFlags[@]}" "''${entryFlags[@]}" "''${cmakeStaticLibFlags[@]}" ${lib.cmakeBool "MAIN12" true}
    setCMakeEntry EXTRA_LIB "x265-10.a;x265-12.a"
    setCMakeEntry EXTRA_LINK_FLAGS "-L."
    setCMakeEntryBool LINKED_10BIT ON
    setCMakeEntryBool LINKED_12BIT ON
  '';

  preBuild = lib.optionalString multibitdepthSupport ''
    make -C ../build-10bits -j $NIX_BUILD_CORES
    make -C ../build-12bits -j $NIX_BUILD_CORES
    ln -s ../build-10bits/libx265.a ./libx265-10.a
    ln -s ../build-12bits/libx265.a ./libx265-12.a
  '';

  doCheck = unittestsSupport;

  checkPhase = ''

    ./test/TestBench

  '';

  postInstall = ''
    rm -f ${placeholder "out"}/lib/*.a
  ''
  + lib.optionalString stdenv.hostPlatform.isMinGW ''
    ln -s $out/bin/*.dll $out/lib
  '';

  meta = {
    description = "Library for encoding H.265/HEVC video streams";
    mainProgram = "x265";
    homepage = "https://www.x265.org";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.all;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "multicorewareinc" finalAttrs.version;
  };
})
