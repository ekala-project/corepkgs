# C programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "c";
    defaultPackage = pkgs: pkgs.gcc;
  };
in

mod { inherit config lib pkgs; }
