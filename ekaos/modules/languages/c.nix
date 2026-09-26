# Adios port of ekaos/modules/languages/c.nix.
# C programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "c";
  defaultPackage = pkgs: pkgs.gcc;
}
