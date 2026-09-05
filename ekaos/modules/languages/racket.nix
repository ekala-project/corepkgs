# Racket programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "racket";
    defaultPackage = pkgs: pkgs.racket;
  };
in

mod { inherit config lib pkgs; }
