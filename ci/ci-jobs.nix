let
  allPkgs = import ./packages.nix;
in
allPkgs.buildable
