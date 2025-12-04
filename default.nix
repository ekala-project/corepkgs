{
  overlays ? [ ],
  ...
}@args:

let
  pins = import ./pins.nix;

  inherit (pins) lib;

  filteredArgs = builtins.removeAttrs args [ "overlays" ];
in

import ./stdenv/impure.nix (
  {
    inherit overlays;
  }
  // filteredArgs
)
