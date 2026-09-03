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
    llvmPkgs.llvm
    llvmPkgs.lld
    llvmPkgs.libclang
    zlib
    libxml2
  ];

  cmakeFlags = [
    # Static LLVM avoids dynamic linking issues (musl vs glibc interpreter)
    "-DZIG_STATIC_LLVM=ON"
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

  # Zig's self-hosted compiler produces a musl-linked binary even on glibc
  # systems. Patch the interpreter to the nix glibc dynamic linker.
  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zig
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
