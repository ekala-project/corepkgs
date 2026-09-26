# Adios port of ekaos/modules/languages/javascript.nix.
# JavaScript programming language module
#
# Usage:
#   languages.javascript.enable = true;
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "javascript";
  defaultPackage = pkgs: pkgs.nodejs;
  resolveVersion = langLib.mkMajorVersionResolver "nodejs";
  environmentVariables = _: {
    NODE_PATH = "$HOME/.node_modules";
  };
  sessionPath = _: [ "$HOME/.node_modules/.bin" ];
}
