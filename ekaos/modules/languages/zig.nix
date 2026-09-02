# Zig programming language module
#
# Provides languages.zig options for system-wide and per-user configuration.
#
# Usage:
#   languages.zig.enable = true;
#   languages.zig.version = "0.15";  # optional: select specific version
#
#   # Per-user:
#   users.users.alice.languages.zig.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}:

let
  mkLanguageModule = import ./lib.nix { inherit lib; };
  mod = mkLanguageModule {
    name = "zig";
    defaultPackage = pkgs: pkgs.zig;
    defaultLspPackage = pkgs: pkgs.zls or null;
    environmentVariables = _: {
      ZIG_GLOBAL_CACHE_DIR = "$HOME/.cache/zig";
    };
  };
in

mod { inherit config lib pkgs; }
