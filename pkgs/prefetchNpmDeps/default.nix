# prefetch-npm-deps: CLI tool for computing npm deps hash
#
# core-pkgs doesn't have the full Rust/Cargo infrastructure to build
# prefetch-npm-deps from source, so we import the implementation from nixpkgs.

{ }:

let
  # Import nixpkgs prefetch-npm-deps binary
  nixpkgs = import <nixpkgs> { };
in
nixpkgs.prefetch-npm-deps
