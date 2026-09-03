{
  version,
  src-url,
  src-hash,
  llvm-major,
  ...
}:

{
  lib,
  stdenv,
  fetchurl,
  cmake,
  ninja,
  zlib,
  libxml2,
  callPackage,
  llvm,
}:

let
  llvmPkgs = llvm.${"v" + llvm-major}.pkgs;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "zig";
  inherit version;

  src = fetchurl {
    url = src-url;
    hash = src-hash;
  };

  nativeBuildInputs = [
    cmake
    ninja
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    llvmPkgs.llvm
    llvmPkgs.lld
    llvmPkgs.libclang
    zlib
    libxml2
  ];

  cmakeFlags = [
    "-DZIG_STATIC_LLVM=OFF"
    "-DZIG_TARGET_MCPU=baseline"
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    "-DZIG_TARGET_TRIPLE=${stdenv.hostPlatform.qemuArch}-linux-gnu"
  ];

  configurePhase = "cmakeConfigurePhase";
  buildPhase = "ninjaBuildPhase";

  enableParallelBuilding = true;

  doCheck = false;

  preBuild = ''
    export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-cache
    export ZIG_LOCAL_CACHE_DIR=$TMPDIR/zig-cache
  '';

  postInstall = ''
    ln -s $out/bin/zig $out/bin/zig-${lib.versions.majorMinor version} || true
  '';

  passthru = {
    hook = callPackage ./setup-hook.nix { zig = finalAttrs.finalPackage; };
  };

  meta = {
    description = "General-purpose programming language and toolchain for maintaining robust, optimal, and reusable software";
    homepage = "https://ziglang.org/";
    changelog = "https://ziglang.org/download/${version}/release-notes.html";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix ++ lib.platforms.darwin;
    mainProgram = "zig";
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "ziglang" version;
  };
})
