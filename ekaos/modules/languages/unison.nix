# Adios port of ekaos/modules/languages/unison.nix.
# Unison programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "unison";
  defaultPackage = pkgs: pkgs.unison-ucm;
}
