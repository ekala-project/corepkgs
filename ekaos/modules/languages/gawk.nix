# GNU Awk programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "gawk";
    defaultPackage = pkgs: pkgs.gawk;
  };
in

mod { inherit config lib pkgs; }
