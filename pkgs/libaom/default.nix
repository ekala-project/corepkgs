{
  lib,
  stdenv,
  fetchgit,
  nasm,
  perl,
  cmake,
  pkg-config,
  python3,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "libaom";
  version = "3.15.0";

  src = fetchgit {
    url = "https://aomedia.googlesource.com/aom";
    tag = "v${finalAttrs.version}";
    hash = "sha256-TixZQP06TEZPtpHvWVOEagzHtXW9hqXWweO2yimBDG4=";
  };

  nativeBuildInputs = [
    nasm
    perl
    cmake
    cmake.configurePhaseHook
    pkg-config
    python3
  ];

  env = lib.optionalAttrs stdenv.hostPlatform.isFreeBSD {
    # This can be removed when we switch to libcxx from llvm 20
    # https://github.com/llvm/llvm-project/pull/122361
    NIX_CFLAGS_COMPILE = "-D_XOPEN_SOURCE=700";
  };

  preConfigure = ''
    # build uses `git describe` to set the build version
    cat > $NIX_BUILD_TOP/git << "EOF"
    #!${stdenv.shell}
    echo v${finalAttrs.version}
    EOF
    chmod +x $NIX_BUILD_TOP/git
    export PATH=$NIX_BUILD_TOP:$PATH
  '';

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
    "-DENABLE_TESTS=OFF"
    # TODO(corepkgs): Enable when libvmaf is packaged.
    "-DCONFIG_TUNE_VMAF=0"
  ]
  ++ lib.optionals (stdenv.isCross && !stdenv.hostPlatform.isx86) [
    "-DCMAKE_ASM_COMPILER=${lib.getBin stdenv.cc}/bin/${stdenv.cc.targetPrefix}cc"
  ]
  ++ lib.optionals stdenv.hostPlatform.isAarch32 [
    # armv7l-hf-multiplatform does not support NEON
    "-DENABLE_NEON=0"
  ];

  postFixup = ''
    # Fix broken pkgconfig paths (double slashes from cmake prefix joining)
    sed -i "s|libdir=.*|libdir=$out/lib|" "$dev/lib/pkgconfig/aom.pc"
    sed -i "s|includedir=.*|includedir=$dev/include|" "$dev/lib/pkgconfig/aom.pc"
    moveToOutput lib/libaom.a "$static"
    # Fix cmake export files to reference the static output for libaom.a
    sed -i "s|$out/lib/libaom.a|$static/lib/libaom.a|g" "$dev"/lib/cmake/aom/aomTargets*.cmake
  ''
  + lib.optionalString stdenv.hostPlatform.isStatic ''
    ln -s $static $out
  '';

  outputs = [
    "out"
    "bin"
    "dev"
    "static"
  ];

  meta = {
    description = "Alliance for Open Media AV1 codec library";
    homepage = "https://aomedia.org/av1-features/get-started/";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.all;
    outputsToInstall = [ "bin" ];
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "aomedia" finalAttrs.version;
  };
})
