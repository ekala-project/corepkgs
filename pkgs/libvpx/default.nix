{
  lib,
  stdenv,
  fetchFromGitHub,
  perl,
  nasm,
  vp8DecoderSupport ? true,
  vp8EncoderSupport ? true,
  vp9DecoderSupport ? true,
  vp9EncoderSupport ? true,
  postprocSupport ? true,
  multithreadSupport ? true,
  spatialResamplingSupport ? true,
  vp9HighbitdepthSupport ? true,
  optimizationsSupport ? true,
  runtimeCpuDetectSupport ? true,
  webmIOSupport ? true,
  libyuvSupport ? true,
  temporalDenoisingSupport ? true,
  examplesSupport ? true,
}:

let
  inherit (stdenv.hostPlatform)
    is64bit
    isMips
    isDarwin
    isCygwin
    ;
  inherit (lib) enableFeature;

  cpu =
    if stdenv.hostPlatform.isArmv7 then
      "armv7"
    else if stdenv.hostPlatform.isAarch64 then
      "arm64"
    else if stdenv.hostPlatform.isx86_32 then
      "x86"
    else if (stdenv.hostPlatform.isPower64 && stdenv.hostPlatform.isLittleEndian) then
      "ppc64le"
    else
      stdenv.hostPlatform.parsed.cpu.name;

  kernel =
    if stdenv.hostPlatform.isBSD then
      "linux"
    else if stdenv.hostPlatform.isDarwin then
      "darwin14"
    else
      stdenv.hostPlatform.parsed.kernel.name;

  isGeneric =
    (
      stdenv.hostPlatform.isPower
      && !(stdenv.hostPlatform.isPower64 && stdenv.hostPlatform.isLittleEndian)
    )
    || stdenv.hostPlatform.parsed.cpu.name == "armv6l"
    || stdenv.hostPlatform.isLoongArch64
    || stdenv.hostPlatform.isRiscV;

  target =
    if
      (
        stdenv.hostPlatform.isBSD
        || stdenv.hostPlatform != stdenv.buildPlatform
        || stdenv.hostPlatform.isLoongArch64
      )
    then
      (if isGeneric then "generic-gnu" else "${cpu}-${kernel}-gcc")
    else
      null;
in

stdenv.mkDerivation (finalAttrs: {
  pname = "libvpx";
  version = "1.16.0";

  src = fetchFromGitHub {
    owner = "webmproject";
    repo = "libvpx";
    rev = "v${finalAttrs.version}";
    hash = "sha256-z1Ov3BHnAGuayeY4D86oTRiDfuZ2Wpc4ZD7pXGaakVI=";
  };

  postPatch = ''
    patchShebangs --build \
      build/make/*.sh \
      build/make/*.pl \
      build/make/*.pm \
      test/*.sh \
      configure

    substituteInPlace configure \
      --replace "check_add_cflags -Wparentheses-equality" "" \
      --replace "check_add_cflags -Wunreachable-code-loop-increment" "" \
      --replace "check_cflags -Wshorten-64-to-32 && add_cflags_only -Wshorten-64-to-32" ""
  '';

  outputs = [
    "bin"
    "dev"
    "out"
  ];
  setOutputFlags = false;

  configurePlatforms = [ ];
  configureFlags = [
    (enableFeature (vp8EncoderSupport || vp8DecoderSupport) "vp8")
    (enableFeature vp8EncoderSupport "vp8-encoder")
    (enableFeature vp8DecoderSupport "vp8-decoder")
    (enableFeature (vp9EncoderSupport || vp9DecoderSupport) "vp9")
    (enableFeature vp9EncoderSupport "vp9-encoder")
    (enableFeature vp9DecoderSupport "vp9-decoder")
    "--disable-install-docs"
    (enableFeature examplesSupport "install-bins")
    "--enable-install-libs"
    "--disable-install-srcs"
    (enableFeature (!isCygwin) "pic")
    (enableFeature optimizationsSupport "optimizations")
    (enableFeature runtimeCpuDetectSupport "runtime-cpu-detect")
    "--enable-libs"
    (enableFeature examplesSupport "examples")
    "--disable-docs"
    "--as=nasm"
    "--size-limit=5120x3200"
    "--disable-codec-srcs"
    (enableFeature isMips "dequant-tokens")
    (enableFeature isMips "dc-recon")
    (enableFeature postprocSupport "postproc")
    (enableFeature (postprocSupport && (vp9DecoderSupport || vp9EncoderSupport)) "vp9-postproc")
    (enableFeature multithreadSupport "multithread")
    (enableFeature spatialResamplingSupport "spatial-resampling")
    (if isDarwin || isCygwin then "--enable-static --disable-shared" else "--enable-shared")
    (enableFeature webmIOSupport "webm-io")
    (enableFeature libyuvSupport "libyuv")
    (enableFeature temporalDenoisingSupport "temporal-denoising")
    (enableFeature (
      temporalDenoisingSupport && (vp9DecoderSupport || vp9EncoderSupport)
    ) "vp9-temporal-denoising")
    (enableFeature (vp9HighbitdepthSupport && is64bit) "vp9-highbitdepth")
  ]
  ++ lib.optionals (target != null) [
    "--target=${target}"
  ];

  nativeBuildInputs = [
    perl
    nasm
  ];

  env.NIX_LDFLAGS = toString [ "-lpthread" ];

  enableParallelBuilding = true;

  postInstall = ''moveToOutput bin "$bin" '';

  meta = {
    description = "WebM VP8/VP9 codec SDK";
    homepage = "https://www.webmproject.org/";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.all;
  };
})
