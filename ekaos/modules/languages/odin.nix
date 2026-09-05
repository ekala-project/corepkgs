# Odin programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "odin";
    defaultPackage = pkgs: pkgs.odin;
  };
in

mod { inherit config lib pkgs; }
