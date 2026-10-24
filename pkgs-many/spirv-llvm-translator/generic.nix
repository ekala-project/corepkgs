{
  version,
  llvmMajor,
  hash,
  packageAtLeast,
  packageOlder,
  ...
}@variantArgs:

{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  lit,
  llvm ? null,
  spirv-headers,
  spirv-tools,
}:

let
  # Look up the LLVM package scope matching the variant's major version.
  # The llvm mkManyVariants package exposes each version as llvm.v<N>.
  llvmPkgs = llvm."v${llvmMajor}".pkgs;
  llvmLib = llvmPkgs.llvm;
in
stdenv.mkDerivation {
  pname = "SPIRV-LLVM-Translator";
  inherit version;

  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "SPIRV-LLVM-Translator";
    tag = "v${version}";
    inherit hash;
  };

  patches = [ ];

  nativeBuildInputs = [
    pkg-config
    cmake
    cmake.configurePhaseHook
    llvmLib.dev
  ];

  buildInputs = [
    spirv-headers
    spirv-tools
    llvmLib
  ];

  nativeCheckInputs = [ lit ];

  cmakeEntries = {
    LLVM_INCLUDE_TESTS = "ON";
    LLVM_DIR = "${llvmLib.dev}";
    BUILD_SHARED_LIBS = "YES";
    LLVM_SPIRV_BUILD_EXTERNAL = "YES";
    CMAKE_SKIP_BUILD_RPATH = "ON";
    LLVM_EXTERNAL_SPIRV_HEADERS_SOURCE_DIR = "${spirv-headers.src}";
    ${if packageAtLeast "19" then "BASE_LLVM_VERSION" else null} =
      "${lib.versions.majorMinor llvmLib.version}.0";
  };

  makeFlags = [
    "all"
    "llvm-spirv"
  ];

  postInstall = ''
    install -D tools/llvm-spirv/llvm-spirv $out/bin/llvm-spirv
  ''
  + lib.optionalString stdenv.hostPlatform.isDarwin ''
    install_name_tool $out/bin/llvm-spirv \
      -change @rpath/libLLVMSPIRVLib.dylib $out/lib/libLLVMSPIRVLib.dylib
  '';

  meta = {
    homepage = "https://github.com/KhronosGroup/SPIRV-LLVM-Translator";
    description = "Tool and a library for bi-directional translation between SPIR-V and LLVM IR";
    mainProgram = "llvm-spirv";
    license = lib.licenses.ncsa;
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "khronos" version;
  };
}
