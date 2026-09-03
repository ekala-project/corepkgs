# Jsonnet data templating language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "jsonnet";
    defaultPackage = pkgs: pkgs.jsonnet;
  };
in

mod { inherit config lib pkgs; }
