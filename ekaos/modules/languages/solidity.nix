# Solidity programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "solidity";
    defaultPackage = pkgs: pkgs.solc;
  };
in

mod { inherit config lib pkgs; }
