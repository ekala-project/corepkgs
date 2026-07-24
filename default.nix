{
  overlays ? [ ],
  ...
}@args:

let
  pins = import ./pins.nix;

  lib = import pins.lib;

  filteredArgs = removeAttrs args [ "overlays" ];
  pkgs = import ./stdenv/impure.nix (
    {
      inherit overlays;
    }
    // filteredArgs
  );
in
pkgs
# lib.recurseIntoAttrs pkgs
