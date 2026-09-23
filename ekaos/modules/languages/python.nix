# Python programming language module
#
# Usage:
#   languages.python.enable = true;
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
  };
in

mod { inherit config lib pkgs; }
