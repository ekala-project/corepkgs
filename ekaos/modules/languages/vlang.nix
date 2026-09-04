# V programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "vlang";
    defaultPackage = pkgs: pkgs.vlang;
  };
in

mod { inherit config lib pkgs; }
