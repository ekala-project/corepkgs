# Nix language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "nix";
    defaultPackage = pkgs: pkgs.nix;
  };
in

mod { inherit config lib pkgs; }
