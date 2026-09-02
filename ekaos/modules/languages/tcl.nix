# Tcl programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "tcl";
    defaultPackage = pkgs: pkgs.tcl;
  };
in

mod { inherit config lib pkgs; }
