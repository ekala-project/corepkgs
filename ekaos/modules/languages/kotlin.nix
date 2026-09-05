# Kotlin programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "kotlin";
    defaultPackage = pkgs: pkgs.kotlin;

  };
in

mod { inherit config lib pkgs; }
