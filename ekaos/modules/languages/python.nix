# Python programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "python";
    defaultPackage = pkgs: pkgs.python3;
    defaultLspPackage = pkgs: pkgs.pyright;
  };
in

mod { inherit config lib pkgs; }
