let
  inherit (import ./pins.nix) lib;
in lib.extend(self: _: {
  systems = import ./systems { lib = self; };

  # Backwards compatibly alias
  platforms = self.systems.doubles;

  # This repo is curated as a set, references to a particular maintainer is
  # likely an error
  maintainers = { };
})
