# Raku programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "raku";
    defaultPackage = pkgs: pkgs.rakudo;
  };
in

mod { inherit config lib pkgs; }
