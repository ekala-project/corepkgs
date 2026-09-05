# JavaScript programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "javascript";
    defaultPackage = pkgs: pkgs.nodejs;
    defaultLspPackage = pkgs: pkgs.typescript-language-server;
    resolveVersion = langLib.mkMajorVersionResolver "nodejs";
    environmentVariables = _: {
      NODE_PATH = "$HOME/.node_modules";
    };
    sessionPath = _: [ "$HOME/.node_modules/.bin" ];
  };
in

mod { inherit config lib pkgs; }
