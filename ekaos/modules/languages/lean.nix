# Adios port of ekaos/modules/languages/lean.nix.
# Lean 4 programming language / theorem prover module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "lean";
  defaultPackage = pkgs: pkgs.lean4;
}
