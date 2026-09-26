# Adios port of ekaos/modules/languages/vlang.nix.
# V programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "vlang";
  defaultPackage = pkgs: pkgs.vlang;
}
