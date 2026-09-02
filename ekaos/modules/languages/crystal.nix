# Crystal programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "crystal";
    defaultPackage = pkgs: pkgs.crystal;
    defaultLspPackage = pkgs: pkgs.crystalline or null;
  };
in

mod { inherit config lib pkgs; }
