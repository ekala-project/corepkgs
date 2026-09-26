# Adios port of ekaos/modules/languages/sml.nix.
# Standard ML programming language module (MLton)
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "sml";
  defaultPackage = pkgs: pkgs.mlton;
}
