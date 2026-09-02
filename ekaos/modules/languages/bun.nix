# Bun JavaScript runtime module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "bun";
    defaultPackage = pkgs: pkgs.bun;
    environmentVariables = _: {
      BUN_INSTALL = "$HOME/.bun";
    };
    sessionPath = _: [ "$HOME/.bun/bin" ];
  };
in

mod { inherit config lib pkgs; }
