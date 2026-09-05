# CUE data constraint language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "cue";
    defaultPackage = pkgs: pkgs.cue;
  };
in

mod { inherit config lib pkgs; }
