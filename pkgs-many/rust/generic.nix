{
  version,
  rustcSha256,
  bootstrapVersion,
  bootstrapHashes,
  enableRustcDev ? true,
  rustcPatches ? [ ],
  mkVariantPassthru,
  ...
}@variantArgs:

{
  stdenv,
  lib,
  newScope,
  callPackage,
  pkgsBuildTarget,
  pkgsBuildBuild,
  pkgsBuildHost,
  pkgsHostTarget,
  pkgsTargetTarget,
  makeRustPlatform,
  wrapRustcWith,
  llvmPackages,
  llvm,
  wrapCCWith,
  overrideCC,
  fetchpatch,
}:

let
  llvmSharedFor =
    pkgSet:
    pkgSet.llvmPackages.libllvm.override (
      {
        enableSharedLibraries = true;
      }
      // lib.optionalAttrs (stdenv.targetPlatform.useLLVM or false) {
        # Force LLVM to compile using clang + LLVM libs when targeting pkgsLLVM
        stdenv = pkgSet.stdenv.override {
          allowedRequisites = null;
          cc = pkgSet.pkgsBuildHost.llvmPackages.clangUseLLVM;
        };
      }
    );

  llvmShared = llvmSharedFor pkgsHostTarget;
  llvmSharedForBuild = llvmSharedFor pkgsBuildBuild;
  llvmSharedForHost = llvmSharedFor pkgsBuildHost;
  llvmSharedForTarget = llvmSharedFor pkgsBuildTarget;

  selectRustPackage = pkgs: pkgs.rust.v1_91;

  # Use `import` to make sure no packages sneak in here.
  lib' = import ../../build-support/rust/lib {
    inherit
      lib
      stdenv
      pkgsBuildHost
      pkgsBuildTarget
      pkgsTargetTarget
      ;
  };

  # Allow faster cross compiler generation by reusing Build artifacts
  fastCross =
    (stdenv.buildPlatform == stdenv.hostPlatform) && (stdenv.hostPlatform != stdenv.targetPlatform);

  packages = {
    prebuilt = callPackage ./bootstrap.nix {
      version = bootstrapVersion;
      hashes = bootstrapHashes;
    };
    stable = lib.makeScope newScope (
      self:
      let
        # Like `buildRustPackages`, but may also contain prebuilt binaries to
        # break cycle. Just like `bootstrapTools` for nixpkgs as a whole,
        # nothing in the final package set should refer to this.
        bootstrapRustPackages =
          if fastCross then
            pkgsBuildBuild.rust.pkgs
          else
            self.buildRustPackages.overrideScope (
              _: _:
              lib.optionalAttrs (stdenv.buildPlatform == stdenv.hostPlatform)
                (selectRustPackage pkgsBuildHost).packages.prebuilt
            );
        bootRustPlatform = makeRustPlatform bootstrapRustPackages;
      in
      {
        # Packages suitable for build-time, e.g. `build.rs`-type stuff.
        buildRustPackages = (selectRustPackage pkgsBuildHost).packages.stable;
        # Analogous to stdenv
        rustPlatform = makeRustPlatform self.buildRustPackages;
        rustc-unwrapped = self.callPackage ./rustc.nix {
          inherit version;
          sha256 = rustcSha256;
          inherit enableRustcDev;
          inherit
            llvmShared
            llvmSharedForBuild
            llvmSharedForHost
            llvmSharedForTarget
            llvmPackages
            fastCross
            ;

          patches = rustcPatches;

          # Use boot package set to break cycle
          inherit (bootstrapRustPackages) cargo rustc rustfmt;
        };
        rustc = wrapRustcWith {
          inherit (self) rustc-unwrapped;
          sysroot = if fastCross then self.rustc-unwrapped else null;
        };
        rustfmt = self.callPackage ./rustfmt.nix {
          inherit (self.buildRustPackages) rustc;
        };
        cargo =
          if (!fastCross) then
            self.callPackage ./cargo.nix {
              # Use boot package set to break cycle
              rustPlatform = bootRustPlatform;
            }
          else
            self.callPackage ./cargo_cross.nix { };
        cargo-auditable = self.callPackage ./cargo-auditable.nix { };
        cargo-auditable-cargo-wrapper = self.callPackage ./cargo-auditable-cargo-wrapper.nix { };
        clippy-unwrapped = self.callPackage ./clippy.nix { };
        clippy = if !fastCross then self.clippy-unwrapped else self.callPackage ./clippy-wrapper.nix { };
      }
    );
  };

  rustc = packages.stable.rustc;
in

# Return rustc wrapper as the main derivation; expose everything via passthru
rustc.overrideAttrs (oldAttrs: {
  passthru =
    (oldAttrs.passthru or { })
    // mkVariantPassthru variantArgs
    // {
      # The full scope, analogous to llvm's `passthru.pkgs`
      pkgs = packages.stable;
      inherit packages;
      lib = lib';
      inherit (lib')
        toTargetArch
        toTargetOs
        toRustTarget
        toRustTargetSpec
        IsNoStdTarget
        toRustTargetForUseInEnvVars
        envVars
        ;
      inherit variantArgs;
    };
})
