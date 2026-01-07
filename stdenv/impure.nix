/*
  Impure default args for `pkgs/top-level/default.nix`. See that file
  for the meaning of each argument.
*/

{
  # We put legacy `system` into `localSystem`, if `localSystem` was not passed.
  # If neither is passed, assume we are building packages on the current
  # (build, in GNU Autotools parlance) platform.
  localSystem ? {
    system = args.system or builtins.currentSystem;
  },

  # These are needed only because nix's `--arg` command-line logic doesn't work
  # with unnamed parameters allowed by ...
  system ? localSystem.system,
  crossSystem ? localSystem,

  # Fallback: The contents of the configuration file found at $NIXPKGS_CONFIG or
  # $HOME/.config/nixpkgs/config.nix.
  config ? { },

  # Overlays are used to extend Nixpkgs collection with additional
  # collections of packages.  These collection of packages are part of the
  # fix-point made by Nixpkgs.
  overlays ? [ ],

  crossOverlays ? [ ],

  ...
}@args:

# If `localSystem` was explicitly passed, legacy `system` should
# not be passed, and vice-versa.
assert args ? localSystem -> !(args ? system);
assert args ? system -> !(args ? localSystem);

import ./pure.nix (
  removeAttrs args [ "system" ]
  // {
    inherit config overlays localSystem;
  }
)
