# Adios port of ekaos/modules/languages/odin.nix.
# Odin programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "odin";
  defaultPackage = pkgs: pkgs.odin;
}
