# Adios port of ekaos/modules/languages/hare.nix.
# Hare programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "hare";
  defaultPackage = pkgs: pkgs.hare;
}
