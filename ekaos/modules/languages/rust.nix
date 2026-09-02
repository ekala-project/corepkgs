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
  mkLanguageModule = import ./lib.nix { inherit lib; };

  # Rust variants expose rustc as the main derivation with passthru.pkgs
  # containing cargo, clippy, rustfmt, etc. The version resolver returns
  # the rustc package; companion tools are accessed via passthru.
  resolveRustVersion =
    pkgs': version:
    let
      parts = lib.splitString "." version;
      major = builtins.elemAt parts 0;
      minor = builtins.elemAt parts 1;
      variantName = "v${major}_${minor}";
      variant = pkgs'.rust.${variantName} or null;
    in
    if variant != null then
      variant
    else
      let
        availableNames = builtins.filter (n: builtins.match "v[0-9]+_[0-9]+" n != null) (
          builtins.attrNames pkgs'.rust
        );
        available = builtins.map (
          n:
          let
            m = builtins.match "v([0-9]+)_([0-9]+)" n;
          in
          "${builtins.elemAt m 0}.${builtins.elemAt m 1}"
        ) availableNames;
      in
      throw "languages.rust: version \"${version}\" is not available. Known versions: ${lib.concatStringsSep ", " available}";

  mod = mkLanguageModule {
    name = "rust";
    defaultPackage = pkgs': pkgs'.rust;
    resolveVersion = resolveRustVersion;
    defaultLspPackage = pkgs': pkgs'.rust-analyzer or null;
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

    extraConfig =
      cfg: _pkgs':
      let
        rustPkgs = cfg.package.pkgs or { };
      in
      {
        environment.systemPackages =
          lib.optional (cfg.cargo.enable && rustPkgs ? cargo) rustPkgs.cargo
          ++ lib.optional (cfg.clippy.enable && rustPkgs ? clippy) rustPkgs.clippy
          ++ lib.optional (cfg.rustfmt.enable && rustPkgs ? rustfmt) rustPkgs.rustfmt;
      };
  };
in

mod { inherit config lib pkgs; }
