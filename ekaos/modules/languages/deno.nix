# Deno JavaScript/TypeScript runtime module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "deno";
    defaultPackage = pkgs: pkgs.deno;
    environmentVariables = _: {
      DENO_DIR = "$HOME/.cache/deno";
    };
  };
in

mod { inherit config lib pkgs; }
