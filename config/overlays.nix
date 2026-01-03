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
    overlays.python = mkOption {
      type = types.listOf overlayType;
      default = [ ];
      description = ''
        Overlays to be applied to each python package set.
      '';
    };
  };
}
