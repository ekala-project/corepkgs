# Node.js programming language module
#
# Usage:
#   languages.nodejs.enable = true;
#   languages.nodejs.version = "22";  # optional: select specific version
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
    environmentVariables = _: {
      NODE_PATH = "$HOME/.node_modules";
    };
    sessionPath = _: [ "$HOME/.node_modules/.bin" ];
  };
in

mod { inherit config lib pkgs; }
