# Adios port of ekaos/modules/languages/purescript.nix.
# PureScript programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "purescript";
  defaultPackage = pkgs: pkgs.purescript;
}
