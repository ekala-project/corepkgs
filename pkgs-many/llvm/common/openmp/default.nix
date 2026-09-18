{
  lib,
  stdenv,
  llvm_meta,
  release_version,
  monorepoSrc ? null,
  src ? null,
  runCommand,
  cmake,
  ninja,
  llvm,
  lit,
  clang-unwrapped,
  perl,
  pkg-config,
  python3,
  version,
  devExtraCmakeFlags ? [ ],
  ompdSupport ? true,
  ompdGdbSupport ? ompdSupport,
  getVersionFile,
  fetchpatch,
}:

assert lib.assertMsg (ompdGdbSupport -> ompdSupport) "OMPD GDB support requires OMPD support!";

stdenv.mkDerivation (finalAttrs: {
  pname = "openmp";
  inherit version;

  src =
    if monorepoSrc != null then
      runCommand "openmp-src-${version}" { inherit (monorepoSrc) passthru; } ''
        mkdir -p "$out"
        cp -r ${monorepoSrc}/cmake "$out"
        cp -r ${monorepoSrc}/openmp "$out"
      ''
    else
      src;

  sourceRoot = "${finalAttrs.src.name}/openmp";

  outputs = [
    "out"
    "dev"
  ];

  patches =
    lib.optional (lib.versionOlder release_version "19") (getVersionFile "openmp/fix-find-tool.patch")
    ++ [
      (getVersionFile "openmp/run-lit-directly.patch")
    ];

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    python3
    perl
    ninja
    pkg-config
    lit
  ];

  buildInputs = [
    llvm
  ]
  ++ lib.optionals (ompdSupport && ompdGdbSupport) [
    python3
  ];

  cmakeEntries = {
    LIBOMP_ENABLE_SHARED = !stdenv.hostPlatform.isStatic && stdenv.hostPlatform.hasSharedLibraries;
    LIBOMP_OMPD_SUPPORT = ompdSupport;
    LIBOMP_OMPD_GDB_SUPPORT = ompdGdbSupport;
    CLANG_TOOL = "${clang-unwrapped}/bin/clang";
    OPT_TOOL = "${llvm}/bin/opt";
    LINK_TOOL = "${llvm}/bin/llvm-link";
  };

  cmakeFlags = devExtraCmakeFlags;

  doCheck = false;

  checkTarget = "check-openmp";

  preCheck = ''
    patchShebangs ../tools/archer/tests/deflake.bash
  '';

  passthru.ekapkgs-update.skip = true;

  meta = llvm_meta // {
    homepage = "https://openmp.llvm.org/";
    description = "Support for the OpenMP language";
    longDescription = ''
      The OpenMP subproject of LLVM contains the components required to build an
      executable OpenMP program that are outside the compiler itself.
      Contains the code for the runtime library against which code compiled by
      "clang -fopenmp" must be linked before it can run and the library that
      supports offload to target devices.
    '';
    # "All of the code is dual licensed under the MIT license and the UIUC
    # License (a BSD-like license)":
    license = with lib.licenses; [
      mit
      ncsa
    ];
  };
})
