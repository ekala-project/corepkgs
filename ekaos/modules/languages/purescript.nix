# PureScript programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "purescript";
    defaultPackage = pkgs: pkgs.purescript;
  };
in

mod { inherit config lib pkgs; }
