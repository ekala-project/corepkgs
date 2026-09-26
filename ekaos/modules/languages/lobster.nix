# Adios port of ekaos/modules/languages/lobster.nix.
# Lobster programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "lobster";
  defaultPackage = pkgs: pkgs.lobster;
}
