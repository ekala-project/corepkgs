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
    defaultLspPackage = pkgs: pkgs.kotlin-language-server or null;
  };
in

mod { inherit config lib pkgs; }
