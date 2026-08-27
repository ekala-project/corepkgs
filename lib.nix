let
  pins = import ./pins.nix;
  lib = import pins.lib;
in
lib.extend (
  self: super: {
    # Deprecated: provided only because nix-lib's `systems.elaborate` gates its
    # compatibility asserts on it. This repo has no legacy release window, so
    # every gate is satisfied. Remove once nix-lib no longer requires it.
    trivial = super.trivial // {
      oldestSupportedReleaseIsAtLeast = _: true;
    };

    # Backwards compatibly alias
    platforms = self.systems.doubles;

    # This repo is curated as a set, references to a particular maintainer is
    # likely an error
    maintainers = { };
  }
)
