# Adios port of ekaos/modules/languages/fortran.nix.
# Fortran programming language module
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "fortran";
  defaultPackage = pkgs: pkgs.gfortran;
}
