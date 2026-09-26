# Adios port of ekaos/modules/languages/tcl.nix.
# Tcl programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "tcl";
  defaultPackage = pkgs: pkgs.tcl;
}
