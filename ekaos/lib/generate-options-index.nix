# Generate a flat JSON index of all ekaos configuration options.
# Used by `ekapkgs search options` to build the search index.
#
# Usage:
#   nix eval --json --file generate-options-index.nix
#   nix eval --json --file generate-options-index.nix --arg configuration ./my-config.nix
{
  pkgs ? import ../../. { },
  lib ? pkgs.lib,
  configuration ? { },
}:

let
  eval =
    (import ../eval-config.nix {
      inherit lib pkgs;
    })
      {
        modules = [ configuration ];
      };

  optionsList = lib.optionAttrSetToDocList eval.options;

  filtered = builtins.filter (o: !(o.internal or false) && (o.visible or true) != false) optionsList;

  safeToJSON =
    v:
    let
      result = builtins.tryEval (builtins.toJSON v);
    in
    if result.success then result.value else null;

  mapped = map (o: {
    name = o.name;
    description = o.description or "";
    type = o.type or "unspecified";
    default = safeToJSON (o.default or null);
    example = safeToJSON (o.example or null);
    declarations = o.declarations or [ ];
    readOnly = o.readOnly or false;
  }) filtered;

in
mapped
