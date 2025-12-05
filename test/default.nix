{ pkgs, callPackage }:

with pkgs;

{
  cc-wrapper =
    with builtins;
    recurseIntoAttrs {
      default = callPackage ./cc-wrapper { };

      supported = stdenv.mkDerivation {
        name = "cc-wrapper-supported";
        builtGCC =
          let
            inherit (lib) filterAttrs;
            sets = lib.pipe gccTests (
              [
                (filterAttrs (_: v: lib.meta.availableOn stdenv.hostPlatform v.stdenv.cc))
                # Broken
                (filterAttrs (n: _: n != "gcc49Stdenv"))
                (filterAttrs (n: _: n != "gccMultiStdenv"))
              ]
              ++ lib.optionals (stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64) [
                # fails with things like
                # ld: warning: ld: warning: object file (trunctfsf2_s.o) was built for newer macOS version (11.0) than being linked (10.5)
                # ld: warning: ld: warning: could not create compact unwind for ___fixunstfdi: register 20 saved somewhere other than in frame
                (filterAttrs (n: _: n != "gcc11Stdenv"))
              ]
            );
          in
          toJSON sets;
      };
    };

  config = callPackage ./config.nix { };

  compress-drv = callPackage ../build-support/compress-drv/test.nix { };

  fetchurl = callPackages ../build-support/fetchurl/tests.nix { };
  fetchtorrent = callPackages ../build-support/fetchtorrent/tests.nix { };
  fetchpatch = callPackages ../build-support/fetchpatch/tests.nix { };
  fetchpatch2 = callPackages ../build-support/fetchpatch/tests.nix { fetchpatch = fetchpatch2; };
  fetchDebianPatch = callPackages ../build-support/fetchdebianpatch/tests.nix { };
  fetchzip = callPackages ../build-support/fetchzip/tests.nix { };
  fetchgit = callPackages ../build-support/fetchgit/tests.nix { };
  fetchFirefoxAddon = callPackages ../build-support/fetchfirefoxaddon/tests.nix { };
  fetchPypiLegacy = callPackages ../build-support/fetchpypilegacy/tests.nix { };

  buildRustCrate = callPackage ../build-support/rust/build-rust-crate/test { };
  importCargoLock = callPackage ../build-support/rust/test/import-cargo-lock { };

  trivial-builders = callPackage ../build-support/trivial-builders/test/default.nix { };

  writers = callPackage ../build-support/writers/test.nix { };

  testers = callPackage ../build-support/testers/test/default.nix { };
}
