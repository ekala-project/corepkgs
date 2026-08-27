let
  pins = import ./pins.nix;
  lib = import pins.lib;
in
lib.extend (
  _: super: {
    # Deprecated: provided only because nix-lib's `systems.elaborate` gates its
    # compatibility asserts on it. This repo has no legacy release window, so
    # every gate is satisfied. Remove once nix-lib no longer requires it.
    trivial = super.trivial // {
      oldestSupportedReleaseIsAtLeast = _: true;
    };
  }
)
