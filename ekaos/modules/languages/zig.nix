# Adios port of ekaos/modules/languages/zig.nix.
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
{ types, pkgs, ... }:

let
  langLib = import ./lib.nix { inherit types; };
in
langLib.mkLanguageModule {
  inherit pkgs;

  name = "zig";
  defaultPackage = pkgs: pkgs.zig;
  environmentVariables = _: {
    ZIG_GLOBAL_CACHE_DIR = "$HOME/.cache/zig";
  };
}
