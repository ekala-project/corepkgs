# Gleam programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "gleam";
    defaultPackage = pkgs: pkgs.gleam;
  };
in

mod { inherit config lib pkgs; }
