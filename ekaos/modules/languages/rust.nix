# Rust programming language module
#
# Provides languages.rust options for system-wide and per-user configuration.
#
# Usage:
#   languages.rust.enable = true;
#   languages.rust.version = "1.98";  # optional: select specific version
#
#   # Include additional tools:
#   languages.rust.cargo.enable = true;   # default: true
#   languages.rust.clippy.enable = true;  # default: true
#   languages.rust.rustfmt.enable = true; # default: true
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
    defaultLspPackage = pkgs': pkgs'.rust-analyzer;
    environmentVariables = _: {
      CARGO_HOME = "$HOME/.cargo";
    };
    sessionPath = _: [ "$HOME/.cargo/bin" ];

    extraOptions = {
      cargo = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to include cargo.";
        };
      };

      clippy = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to include clippy.";
        };
      };

      rustfmt = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to include rustfmt.";
        };
      };
    };

    # Extra module with full config access for wiring companion tools
    imports = [
      (
        { config, lib, ... }:
        let
          cfg = config.languages.rust;
          rustPkgs = cfg.package.pkgs or { };
        in
        {
          config = lib.mkIf cfg.enable {
            environment.packages =
              lib.optional (cfg.cargo.enable && rustPkgs ? cargo) rustPkgs.cargo
              ++ lib.optional (cfg.clippy.enable && rustPkgs ? clippy) rustPkgs.clippy
              ++ lib.optional (cfg.rustfmt.enable && rustPkgs ? rustfmt) rustPkgs.rustfmt;
          };
        }
      )
    ];
  };
in

mod { inherit config lib pkgs; }
