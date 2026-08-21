# nixpkgs configuration options
# Provides nixpkgs.config.allowUnfree and related settings
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.nixpkgs;
in

{
  options = {
    nixpkgs = {
      config = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        example = {
          allowUnfree = true;
          allowBroken = false;
        };
        description = ''
          Configuration for the Nix package set.

          Common options:
          - allowUnfree: Allow packages with unfree licenses
          - allowBroken: Allow packages marked as broken
          - allowInsecure: Allow packages with known vulnerabilities
          - permittedInsecurePackages: List of specific insecure packages to allow
        '';
      };

      overlays = mkOption {
        type = types.listOf (types.anything);
        default = [ ];
        description = ''
          List of overlays to apply to the package set.

          Note: When using the ekaos system builder, overlays should
          be applied when importing the package set, not via this option.
          This option is provided for compatibility.
        '';
      };
    };
  };

  config = {
    assertions = [
      {
        assertion =
          cfg.config ? allowUnfree -> cfg.config.allowUnfree == (pkgs.config.allowUnfree or false);
        message = ''
          nixpkgs.config.allowUnfree is set to ${toString cfg.config.allowUnfree} but the
          package set was imported with allowUnfree = ${toString (pkgs.config.allowUnfree or false)}.

          To use unfree packages, pass the config when importing the package set:
            pkgs = import <core-pkgs> { config.allowUnfree = true; };
          or build the system with:
            nix-build ekaos --arg pkgs 'import ../. { config.allowUnfree = true; }'
        '';
      }
    ];
  };
}
