# Adios port of ekaos/modules/languages/typescript.nix.
# TypeScript programming language module
#
# Usage:
#   languages.typescript.enable = true;
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "typescript";
  defaultPackage = pkgs: pkgs.nodejs;
  resolveVersion = langLib.mkMajorVersionResolver "nodejs";
  environmentVariables = _: {
    NODE_PATH = "$HOME/.node_modules";
  };
  sessionPath = _: [ "$HOME/.node_modules/.bin" ];
}
