{
  callPackages,
  config,
  lib,
  pkgs,
}:

let
  inherit (lib)
    composeManyExtensions
    extends
    makeScope
    ;

  # Writers for JSON-like data structures
  dataWriters = callPackages ./data.nix { };

  # Writers for scripts
  scriptWriters = callPackages ./scripts.nix { };

  baseWriters =
    _:
    scriptWriters
    // dataWriters
    // {
      # Expose pkgs so config.overlays.writers extensions can access system deps
      inherit pkgs;
    };

  extensions = composeManyExtensions config.overlays.writers;
in
# If you are reading this, you can test these writers by running: nix-build . -A tests.writers
makeScope pkgs.newScope (extends extensions baseWriters)
