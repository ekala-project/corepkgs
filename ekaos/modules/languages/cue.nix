# Adios port of ekaos/modules/languages/cue.nix.
# CUE data constraint language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "cue";
  defaultPackage = pkgs: pkgs.cue;
}
