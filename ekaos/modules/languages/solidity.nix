# Adios port of ekaos/modules/languages/solidity.nix.
# Solidity programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "solidity";
  defaultPackage = pkgs: pkgs.solc;
}
