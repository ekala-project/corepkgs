# Adios port of ekaos/modules/languages/shell.nix.
# Shell scripting module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "shell";
  defaultPackage = pkgs: pkgs.bash;
}
