# Adios port of ekaos/modules/languages/go.nix.
# Go programming language module
#
# Provides languages.go options for system-wide and per-user configuration.
#
# Usage:
#   languages.go.enable = true;
#   languages.go.version = "1.27";  # optional: select specific version
#
#   # Per-user:
#   users.users.alice.languages.go.enable = true;
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "go";
  defaultPackage = pkgs: pkgs.go;
  environmentVariables = _: {
    GOPATH = "$HOME/go";
  };
  sessionPath = _: [ "$HOME/go/bin" ];
}
