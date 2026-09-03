# Scala programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "scala";
    defaultPackage = pkgs: pkgs.scala;

  };
in

mod { inherit config lib pkgs; }
