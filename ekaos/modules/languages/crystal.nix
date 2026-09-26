# Adios port of ekaos/modules/languages/crystal.nix.
# Crystal programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "crystal";
  defaultPackage = pkgs: pkgs.crystal;

}
