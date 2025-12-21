{
  overlays ? [ ],
  ...
}@args:

let
  pins = import ./pins.nix;

  inherit (pins) lib;

  filteredArgs = builtins.removeAttrs args [ "overlays" ];
  pkgs = import ./stdenv/impure.nix (
    {
      inherit overlays;
    }
    // filteredArgs
  );
in
lib.recurseIntoAttrs pkgs
