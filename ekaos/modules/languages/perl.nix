# Adios port of ekaos/modules/languages/perl.nix.
# Perl programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "perl";
  defaultPackage = pkgs: pkgs.perl;
}
