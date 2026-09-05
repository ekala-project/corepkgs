# Vala programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "vala";
    defaultPackage = pkgs: pkgs.vala;
  };
in

mod { inherit config lib pkgs; }
