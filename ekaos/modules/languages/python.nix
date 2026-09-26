# Adios port of ekaos/modules/languages/python.nix.
# Python programming language module
#
# Usage:
#   languages.python.enable = true;
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "python";
  defaultPackage = pkgs: pkgs.python3;
}
