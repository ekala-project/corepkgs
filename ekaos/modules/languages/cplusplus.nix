# Adios port of ekaos/modules/languages/cplusplus.nix.
# C++ programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "cplusplus";
  defaultPackage = pkgs: pkgs.gcc;
}
