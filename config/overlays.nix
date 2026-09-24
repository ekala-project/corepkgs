{ lib, ... }:

let
  inherit (lib)
    mkOption
    types
    ;

  overlayType = lib.mkOptionType {
    name = "overlay";
    description = "overlay";
    check = lib.isFunction;
    merge = lib.mergeOneOption;
  };

in
{
  options = {
    overlays.pkgs = mkOption {
      type = types.listOf overlayType;
      default = [ ];
      description = ''
        Overlays to be applied to the top-level package set.
      '';
    };

    overlays.python = mkOption {
      type = types.listOf overlayType;
      default = [ ];
      description = ''
        Overlays to be applied to each python package set.
      '';
    };

    overlays.haskell = mkOption {
      type = types.listOf overlayType;
      default = [ ];
      description = ''
        Overlays to be applied to each haskell package set.
      '';
    };

    overlays.r = mkOption {
      type = types.listOf overlayType;
      default = [ ];
      description = ''
        Overlays to be applied to the R package set.
      '';
    };

    overlays.perl = mkOption {
      type = types.listOf overlayType;
      default = [ ];
      description = ''
        Overlays to be applied to each perl package set.
      '';
    };

    overlays.lua = mkOption {
      type = types.listOf overlayType;
      default = [ ];
      description = ''
        Overlays to be applied to each Lua package set.
      '';
    };

    overlays.cuda = mkOption {
      type = types.listOf overlayType;
      default = [ ];
      description = ''
        Overlays to be applied to each CUDA package set.
      '';
    };

    overlays.linux = mkOption {
      type = types.listOf overlayType;
      default = [ ];
      description = ''
        Overlays to be applied to each Linux kernel packages set.
      '';
    };

    overlays.writers = mkOption {
      type = types.listOf overlayType;
      default = [ ];
      description = ''
        Overlays to be applied to the writers package scope.
      '';
    };
  };
}
