# Adios port of ekaos/modules/languages/gawk.nix.
# GNU Awk programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "gawk";
  defaultPackage = pkgs: pkgs.gawk;
}
