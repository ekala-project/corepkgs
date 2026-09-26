# Adios port of ekaos/modules/languages/nix.nix.
# Nix language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "nix";
  defaultPackage = pkgs: pkgs.nix;
}
