# Typst typesetting language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "typst";
    defaultPackage = pkgs: pkgs.typst;
  };
in

mod { inherit config lib pkgs; }
