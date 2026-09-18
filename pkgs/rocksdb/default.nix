{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  bzip2,
  lz4,
  zlib,
  zstd,
  enableJemalloc ? false,
  jemalloc,
  enableLiburing ? true,
  liburing,
  gflags,
  snappy,
  enableShared ? !stdenv.hostPlatform.isStatic,
  sse42Support ? stdenv.hostPlatform.sse4_2Support,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rocksdb";
  version = "11.8.1";

  src = fetchFromGitHub {
    owner = "facebook";
    repo = "rocksdb";
    tag = "v${finalAttrs.version}";
    hash = "sha256-zjOo0H8/qA879Lcw5wHp2BZzOhl+/wYluxKD9RCfQ+0=";
  };

  patches = lib.optional enableLiburing ./fix-findliburing.patch;

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  propagatedBuildInputs = [
    bzip2
    lz4
    snappy
    zlib
    zstd
  ];

  buildInputs = [
    gflags
  ]
  ++ lib.optional enableJemalloc jemalloc
  ++ lib.optional enableLiburing liburing;

  outputs = [
    "out"
    "tools"
  ];

  cmakeEntries = {
    PORTABLE = "1";
    WITH_JEMALLOC = if enableJemalloc then "1" else "0";
    WITH_LIBURING = if enableLiburing then "1" else "0";
    WITH_JNI = "0";
    WITH_BENCHMARK_TOOLS = "0";
    WITH_TESTS = "1";
    WITH_TOOLS = "0";
    WITH_CORE_TOOLS = "1";
    WITH_BZ2 = "1";
    WITH_LZ4 = "1";
    WITH_SNAPPY = "1";
    WITH_ZLIB = "1";
    WITH_ZSTD = "1";
    WITH_GFLAGS = "1";
    USE_RTTI = "1";
    FAIL_ON_WARNINGS = "NO";
    ${if sse42Support then "FORCE_SSE42" else null} = "1";
    ${if !enableShared then "ROCKSDB_BUILD_SHARED" else null} = "0";
  };

  preInstall = ''
    mkdir -p $tools/bin
    cp tools/{ldb,sst_dump} $tools/bin/
  ''
  + lib.optionalString enableShared ''
    ls -1 $tools/bin/* | xargs -I{} patchelf --set-rpath $out/lib:${lib.getLib stdenv.cc.cc}/lib {}
  '';

  # Old version doesn't ship the .pc file, new version puts wrong paths in there.
  postFixup = ''
    if [ -f "$out"/lib/pkgconfig/rocksdb.pc ]; then
      substituteInPlace "$out"/lib/pkgconfig/rocksdb.pc \
        --replace-warn '="''${prefix}//' '="/'
    fi
  '';

  meta = {
    homepage = "https://rocksdb.org";
    description = "Library that provides an embeddable, persistent key-value store for fast storage";
    changelog = "https://github.com/facebook/rocksdb/raw/v${finalAttrs.version}/HISTORY.md";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "facebook" finalAttrs.version;
  };
})
