# Julia programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "julia";
    defaultPackage = pkgs: pkgs.julia;
    environmentVariables = _: {
      JULIA_DEPOT_PATH = "$HOME/.julia";
    };
  };
in

mod { inherit config lib pkgs; }
