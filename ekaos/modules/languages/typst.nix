# Adios port of ekaos/modules/languages/typst.nix.
# Typst typesetting language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "typst";
  defaultPackage = pkgs: pkgs.typst;
}
