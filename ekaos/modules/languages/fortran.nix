# Fortran programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "fortran";
    defaultPackage = pkgs: pkgs.gfortran;
  };
in

mod { inherit config lib pkgs; }
