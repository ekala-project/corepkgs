# Guile Scheme programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "guile";
    defaultPackage = pkgs: pkgs.guile;
  };
in

mod { inherit config lib pkgs; }
