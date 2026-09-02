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
  llvmPackages_18,
  llvmPackages_19,
  llvmPackages_20,
  llvmPackages_21,
}:

let
  llvmPackages =
    {
      "18" = llvmPackages_18;
      "19" = llvmPackages_19;
      "20" = llvmPackages_20;
      "21" = llvmPackages_21;
    }
    .${llvm-major};
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
    llvmPackages.llvm
    llvmPackages.lld
    llvmPackages.libclang
    zlib
    libxml2
  ];

  cmakeFlags = [
    "-DZIG_STATIC_LLVM=OFF"
    "-DZIG_TARGET_MCPU=baseline"
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
