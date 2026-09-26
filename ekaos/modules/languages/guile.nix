# Adios port of ekaos/modules/languages/guile.nix.
# Guile Scheme programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "guile";
  defaultPackage = pkgs: pkgs.guile;
}
