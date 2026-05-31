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
  llvmPackages_18,
  llvmPackages_19,
  llvmPackages_20,
  llvmPackages_21,
  spirv-headers,
  spirv-tools,
}:

let
  llvmPackages =
    {
      "18" = llvmPackages_18;
      "19" = llvmPackages_19;
      "20" = llvmPackages_20;
      "21" = llvmPackages_21;
    }
    .${llvmMajor};
  llvm = llvmPackages.llvm;
in
stdenv.mkDerivation {
  pname = "SPIRV-LLVM-Translator";
  inherit version;

  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "SPIRV-LLVM-Translator";
    rev = "v${version}";
    inherit hash;
  };

  patches = [ ];

  nativeBuildInputs = [
    pkg-config
    cmake
    cmake.configurePhaseHook
    llvm.dev
  ];

  buildInputs = [
    spirv-headers
    spirv-tools
    llvm
  ];

  nativeCheckInputs = [ lit ];

  cmakeFlags = [
    "-DLLVM_INCLUDE_TESTS=ON"
    "-DLLVM_DIR=${llvm.dev}"
    "-DBUILD_SHARED_LIBS=YES"
    "-DLLVM_SPIRV_BUILD_EXTERNAL=YES"
    "-DCMAKE_SKIP_BUILD_RPATH=ON"
    "-DLLVM_EXTERNAL_SPIRV_HEADERS_SOURCE_DIR=${spirv-headers.src}"
  ]
  ++ lib.optional (packageAtLeast "19") "-DBASE_LLVM_VERSION=${lib.versions.majorMinor llvm.version}.0";

  doCheck = false;

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
    maintainers = [ ];
  };
}
