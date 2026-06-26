# Haskell infrastructure entry point.
#
# Provides:
#   haskell.lib          - Override utilities (dontCheck, doJailbreak, etc.)
#   haskell.compiler     - Available GHC versions
#   haskell.packages     - Per-compiler Haskell package sets
#
# Downstream repos (haskell-packages) inject packages via config.overlays.haskell.

{
  callPackage,
  config,
  lib,
  pkgs,
  buildPackages,
}:

let
  haskellLib = import ./lib/default.nix { inherit pkgs lib; };

  # Build a Haskell package set for a given GHC compiler.
  # This follows the pattern from nixpkgs' haskell-packages.nix.
  mkPackageSet =
    {
      ghc,
      # The attribute name in haskell.packages for this compiler
      ghcAttr,
      compilerConfig ? (_: _: { }),
      packageSetConfig ? (_: _: { }),
    }:
    let
      inherit (lib) extends makeExtensible composeManyExtensions;

      haskellPackages =
        let
          initialPackages = import ./hackage-packages.nix;
        in
        callPackage ./make-package-set.nix {
          inherit lib stdenv;
          inherit (pkgs) buildPackages;
          # Use buildPackages indirection to break recursion.
          # For native builds, buildPackages == pkgs so this is the same set
          # but accessed through a different path, allowing lazy evaluation.
          buildHaskellPackages = buildPackages.haskell.packages.${ghcAttr};
          inherit ghc haskellLib;
          all-cabal-hashes = null;
          extensible-self = finalPackageSet;
          package-set = initialPackages;
        };

      stdenv = pkgs.stdenv;

      # Compose all configuration overlays
      configurationOverlay = composeManyExtensions (
        [
          compilerConfig
          configurationCommon
          configurationNix
          packageSetConfig
        ]
        ++ config.overlays.haskell
      );

      configurationCommon = import ./configuration-common.nix { inherit pkgs haskellLib; };
      configurationNix = import ./configuration-nix.nix { inherit pkgs haskellLib; };

      finalPackageSet = makeExtensible (extends configurationOverlay haskellPackages);

    in
    finalPackageSet;

in
{
  # Re-export haskell.lib for convenience
  lib = haskellLib;

  # Available GHC compilers
  compiler = {
    ghc902Binary = pkgs.ghc.v9_0_2_binary;
    ghc984Binary = pkgs.ghc.v9_8_4_binary;
  };

  # Per-compiler package sets
  packages =
    let
      ghc98Config = import ./configuration-ghc-9.8.x.nix { inherit pkgs haskellLib; };
      ghc90Config = import ./configuration-ghc-9.0.x.nix { };
    in
    {
      ghc984Binary = mkPackageSet {
        ghc = pkgs.ghc.v9_8_4_binary;
        ghcAttr = "ghc984Binary";
        compilerConfig = ghc98Config;
      };

      ghc902Binary = mkPackageSet {
        ghc = pkgs.ghc.v9_0_2_binary;
        ghcAttr = "ghc902Binary";
        compilerConfig = ghc90Config;
      };
    };
}
