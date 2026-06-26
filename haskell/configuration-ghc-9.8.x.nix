# Configuration for GHC 9.8.x
# Primarily nulls out core libraries that ship with GHC.
{ pkgs, haskellLib }:

self: super:

{
  # Disable GHC 9.8.x core libraries.
  array = null;
  base = null;
  binary = null;
  bytestring = null;
  Cabal = null;
  Cabal-syntax = null;
  containers = null;
  deepseq = null;
  directory = null;
  exceptions = null;
  filepath = null;
  ghc-bignum = null;
  ghc-boot = null;
  ghc-boot-th = null;
  ghc-compact = null;
  ghc-heap = null;
  ghc-prim = null;
  ghci = null;
  haskeline = null;
  hpc = null;
  integer-gmp = null;
  libiserv = null;
  mtl = null;
  parsec = null;
  pretty = null;
  process = null;
  rts = null;
  stm = null;
  semaphore-compat = null;
  system-cxx-std-lib = null;
  template-haskell = null;
  terminfo =
    if pkgs.stdenv.hostPlatform == pkgs.stdenv.buildPlatform then null else super.terminfo or null;
  text = null;
  time = null;
  transformers = null;
  unix = null;
  xhtml = null;
  Win32 = null;

  # Not core packages in GHC 9.8
  ghc-experimental = null;
  ghc-internal = null;
  ghc-toolchain = null;
  ghc-platform = null;

  # Becomes a core package in GHC >= 9.10, provide from Hackage for 9.8
  os-string = self.os-string_2_0_10 or null;
}
