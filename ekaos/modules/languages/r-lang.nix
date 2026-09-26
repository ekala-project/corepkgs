# Adios port of ekaos/modules/languages/r-lang.nix.
# R programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "r-lang";
  defaultPackage = pkgs: pkgs.r-lang;
  environmentVariables = _: {
    R_LIBS_USER = "$HOME/.R/library";
  };
}
