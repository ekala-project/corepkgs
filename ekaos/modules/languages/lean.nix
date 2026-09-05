# Lean 4 programming language / theorem prover module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "lean";
    defaultPackage = pkgs: pkgs.lean4;
  };
in

mod { inherit config lib pkgs; }
