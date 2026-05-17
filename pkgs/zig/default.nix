{
  lib,
  stdenv,
  fetchurl,
  cmake,
  ninja,
  llvmPackages_18,
  zlib,
  libxml2,
  callPackage,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "zig";
  version = "0.13.0";

  src = fetchurl {
    url = "https://ziglang.org/download/${finalAttrs.version}/zig-${finalAttrs.version}.tar.xz";
    hash = "sha256-Bsc1lr7sy3HMBzgFvbnA4FdkEo8WR4+lO/F9+rwdQxg=";
  };

  nativeBuildInputs = [
    cmake
    ninja
  ];

  buildInputs = [
    llvmPackages_18.llvm
    llvmPackages_18.lld
    llvmPackages_18.libclang
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

  # Zig tests can be lengthy
  doCheck = false;

  #  Set cache directory to build directory
  preBuild = ''
    export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-cache
    export ZIG_LOCAL_CACHE_DIR=$TMPDIR/zig-cache
  '';

  postInstall = ''
    # Install standard library (it's already installed by cmake)
    # cp -r lib $out/

    # Create version-specific symlink
    ln -s $out/bin/zig $out/bin/zig-${lib.versions.majorMinor finalAttrs.version} || true
  '';

  passthru = {
    hook = callPackage ./setup-hook.nix { zig = finalAttrs.finalPackage; };
  };

  meta = {
    description = "General-purpose programming language and toolchain for maintaining robust, optimal, and reusable software";
    homepage = "https://ziglang.org/";
    changelog = "https://ziglang.org/download/${finalAttrs.version}/release-notes.html";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix ++ lib.platforms.darwin;
    mainProgram = "zig";
    maintainers = [ ];
  };
})
