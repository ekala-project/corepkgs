# Rust programming language module
#
# Provides languages.rust options for system-wide and per-user configuration.
#
# Usage:
#   languages.rust.enable = true;
#   languages.rust.version = "1.98";  # optional: select specific version
#
#   # Per-user:
#   users.users.alice.languages.rust.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}:

let
  langLib = import ./lib.nix { inherit lib; };

  mod = langLib.mkLanguageModule {
    name = "rust";
    defaultPackage = pkgs': pkgs'.rust;
    environmentVariables = _: {
      CARGO_HOME = "$HOME/.cargo";
    };
    sessionPath = _: [ "$HOME/.cargo/bin" ];
  };
in

mod { inherit config lib pkgs; }
