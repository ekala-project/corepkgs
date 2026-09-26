# Adios port of ekaos/modules/languages/raku.nix.
# Raku programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "raku";
  defaultPackage = pkgs: pkgs.rakudo;
}
