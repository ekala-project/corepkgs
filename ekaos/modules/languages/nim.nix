# Nim programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "nim";
    defaultPackage = pkgs: pkgs.nim;
    defaultLspPackage = pkgs: pkgs.nimlsp or null;
    environmentVariables = _: {
      NIMBLE_DIR = "$HOME/.nimble";
    };
    sessionPath = _: [ "$HOME/.nimble/bin" ];
  };
in

mod { inherit config lib pkgs; }
