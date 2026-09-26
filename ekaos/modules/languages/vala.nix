# Adios port of ekaos/modules/languages/vala.nix.
# Vala programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "vala";
  defaultPackage = pkgs: pkgs.vala;
}
