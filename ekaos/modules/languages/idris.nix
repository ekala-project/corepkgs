# Idris2 programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "idris";
    defaultPackage = pkgs: pkgs.idris2;
  };
in

mod { inherit config lib pkgs; }
