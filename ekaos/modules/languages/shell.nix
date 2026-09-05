# Shell scripting module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "shell";
    defaultPackage = pkgs: pkgs.bash;
  };
in

mod { inherit config lib pkgs; }
