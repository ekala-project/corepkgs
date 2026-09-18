{
  lib,
  stdenv,
  llvm_meta,
  release_version,
  buildLlvmPackages,
  monorepoSrc,
  runCommand,
  cmake,
  ninja,
  libxml2,
  libllvm,
  version,
  devExtraCmakeFlags ? [ ],
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "mlir";
  inherit version;

  doCheck =
    (
      !stdenv.hostPlatform.isx86_32 # TODO: why
    )
    && (!stdenv.hostPlatform.isMusl);

  # Blank llvm dir just so relative path works
  src = runCommand "${finalAttrs.pname}-src-${version}" { inherit (monorepoSrc) passthru; } ''
    mkdir -p "$out"
    cp -r ${monorepoSrc}/cmake "$out"
    cp -r ${monorepoSrc}/mlir "$out"
    cp -r ${monorepoSrc}/third-party "$out/third-party"

    mkdir -p "$out/llvm"
  '';

  sourceRoot = "${finalAttrs.src.name}/mlir";

  patches = [
    ./gnu-install-dirs.patch
  ];

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    ninja
  ];

  buildInputs = [
    libllvm
    libxml2
  ];

  cmakeEntries = {
    LLVM_BUILD_TOOLS = true;
    # Install headers as well
    LLVM_INSTALL_TOOLCHAIN_ONLY = false;
    MLIR_TOOLS_INSTALL_DIR = "${placeholder "out"}/bin/";
    LLVM_ENABLE_IDE = false;
    MLIR_INSTALL_PACKAGE_DIR = "${placeholder "dev"}/lib/cmake/mlir";
    MLIR_INSTALL_CMAKE_DIR = "${placeholder "dev"}/lib/cmake/mlir";
    LLVM_BUILD_TESTS = finalAttrs.finalPackage.doCheck;
    LLVM_ENABLE_FFI = true;
    LLVM_HOST_TRIPLE = stdenv.hostPlatform.config;
    LLVM_DEFAULT_TARGET_TRIPLE = stdenv.hostPlatform.config;
    LLVM_ENABLE_DUMP = true;
    LLVM_TABLEGEN_EXE = "${buildLlvmPackages.tblgen}/bin/llvm-tblgen";
    MLIR_TABLEGEN_EXE = "${buildLlvmPackages.tblgen}/bin/mlir-tblgen";
    LLVM_BUILD_LLVM_DYLIB = !stdenv.hostPlatform.isStatic;
    # Disables building of shared libs, -fPIC is still injected by cc-wrapper
    ${if stdenv.hostPlatform.isStatic then "LLVM_ENABLE_PIC" else null} = false;
    ${if stdenv.hostPlatform.isStatic then "LLVM_BUILD_STATIC" else null} = true;
    ${if stdenv.hostPlatform.isStatic then "LLVM_LINK_LLVM_DYLIB" else null} = false;
  };

  cmakeFlags = devExtraCmakeFlags;

  outputs = [
    "out"
    "dev"
  ];

  requiredSystemFeatures = [ "big-parallel" ];
  passthru.ekapkgs-update.skip = true;

  meta = llvm_meta // {
    homepage = "https://mlir.llvm.org/";
    description = "Multi-Level IR Compiler Framework";
    longDescription = ''
      The MLIR project is a novel approach to building reusable and extensible
      compiler infrastructure. MLIR aims to address software fragmentation,
      improve compilation for heterogeneous hardware, significantly reduce
      the cost of building domain specific compilers, and aid in connecting
      existing compilers together.
    '';
  };
})
