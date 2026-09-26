# Adios port of ekaos/modules/languages/gleam.nix.
# Gleam programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "gleam";
  defaultPackage = pkgs: pkgs.gleam;
}
