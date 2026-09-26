# Adios port of ekaos/modules/languages/nodejs.nix.
# Node.js programming language module
#
# Usage:
#   languages.nodejs.enable = true;
#   languages.nodejs.version = "22";  # optional: select specific version
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "nodejs";
  defaultPackage = pkgs: pkgs.nodejs;
  resolveVersion = langLib.mkMajorVersionResolver "nodejs";
  environmentVariables = _: {
    NODE_PATH = "$HOME/.node_modules";
  };
  sessionPath = _: [ "$HOME/.node_modules/.bin" ];
}
