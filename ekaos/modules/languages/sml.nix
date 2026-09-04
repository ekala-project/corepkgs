# Standard ML programming language module (MLton)
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "sml";
    defaultPackage = pkgs: pkgs.mlton;
  };
in

mod { inherit config lib pkgs; }
