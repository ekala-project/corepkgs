let
  lib = import (builtins.fetchGit {
  url = "https://github.com/jonringer/nix-lib.git";
  rev = "f3baad9fc4df31152e6150712204bb391214fdd7";
});
in lib.extend(self: _: {
  systems = import ./systems { lib = self; };

  # Backwards compatibly alias
  platforms = self.systems.doubles;

  # This repo is curated as a set, references to a particular maintainer is
  # likely an error
  maintainers = { };
})
