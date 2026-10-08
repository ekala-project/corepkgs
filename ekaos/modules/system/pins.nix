# Renders pkgs.pins as a Nix file that maps each pin name to its store path.
# The resulting file can be passed as the `pins` argument to default.nix for
# fully offline evaluation (e.g. during installation from an ISO).
#
# Usage:
#   import /path/to/core-pkgs {
#     pins = import /nix/store/...-pins-offline.nix;
#   }
{ pkgs, lib, ... }:

let
  inherit (lib) mkOption types;

  rendered = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: path: "  ${name} = ${path};") pkgs.pins
  );
in
{
  options.system.build.pinsFile = mkOption {
    type = types.package;
    description = "Rendered offline pins file mapping pin names to store paths.";
  };

  config.system.build.pinsFile = pkgs.writeText "pins-offline.nix" ''
    # Auto-rendered offline pins — store paths only, no network access needed.
    # Pass to: import <core-pkgs> { pins = import ./pins-offline.nix; }
    {
    ${rendered}
    }
  '';
}
