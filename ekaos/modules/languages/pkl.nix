# Adios port of ekaos/modules/languages/pkl.nix.
# Pkl configuration language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "pkl";
  defaultPackage = pkgs: pkgs.pkl;
}
