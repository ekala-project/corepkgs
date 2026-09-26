# Adios port of ekaos/modules/languages/racket.nix.
# Racket programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "racket";
  defaultPackage = pkgs: pkgs.racket;
}
