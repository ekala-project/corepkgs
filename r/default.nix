# R package scope.
#
# Downstream repos (r-packages) inject packages via config.overlays.r.
# Uses makeScope so auto-called packages resolve R deps from this scope
# and fall back to pkgs for system dependencies (fetchurl, zlib, etc.).

{
  lib,
  pkgs,
  config,
  buildRPackage,
}:

let
  inherit (lib) makeScope composeManyExtensions extends;

  basePackages = self: {
    inherit buildRPackage;
    # Expose pkgs so config.overlays.r extensions can access system deps
    # (e.g. pkgs.curl.dev) without shadowing from R package names.
    inherit pkgs;
  };

  extensions = composeManyExtensions config.overlays.r;

in
makeScope pkgs.newScope (extends extensions basePackages)
