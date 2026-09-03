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
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };
  mod = langLib.mkLanguageModule {
    name = "go";
    defaultPackage = pkgs: pkgs.go;
    defaultLspPackage = pkgs: pkgs.gopls;
    environmentVariables = _: {
      GOPATH = "$HOME/go";
    };
    sessionPath = _: [ "$HOME/go/bin" ];
  };
in

mod { inherit config lib pkgs; }
