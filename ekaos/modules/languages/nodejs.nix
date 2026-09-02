# Node.js programming language module
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "nodejs";
    defaultPackage = pkgs: pkgs.nodejs;
    resolveVersion = langLib.mkMajorVersionResolver "nodejs";
    defaultLspPackage = pkgs: pkgs.nodePackages.typescript-language-server or null;
    environmentVariables = _: {
      NODE_PATH = "$HOME/.node_modules";
    };
    sessionPath = _: [ "$HOME/.node_modules/.bin" ];
  };
in

mod { inherit config lib pkgs; }
