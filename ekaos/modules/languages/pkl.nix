# Pkl configuration language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "pkl";
    defaultPackage = pkgs: pkgs.pkl;
  };
in

mod { inherit config lib pkgs; }
