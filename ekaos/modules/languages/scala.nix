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
    defaultLspPackage = pkgs: pkgs.metals or null;
  };
in

mod { inherit config lib pkgs; }
