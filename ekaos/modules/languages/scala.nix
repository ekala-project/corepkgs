# Adios port of ekaos/modules/languages/scala.nix.
# Scala programming language module
#
# Usage:
#   languages.scala.enable = true;
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "scala";
  defaultPackage = pkgs: pkgs.scala;
}
