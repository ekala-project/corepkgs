# ekaos system builder
# Main entry point for building ekaos systems
#
# Usage (from a flake):
#
#   core-pkgs.lib.ekaosSystem {
#     system = "x86_64-linux";
#     modules = [ ./configuration.nix ];
#   };
#
{
  system,
  modules ? [ ],
  pkgs ? import ../. { inherit system; },
  lib ? pkgs.lib,
  ...
}@args:

import ./eval-config.nix
  {
    inherit lib pkgs;
  }
  (
    {
      inherit modules;
    }
    // builtins.removeAttrs args [
      "system"
      "pkgs"
      "lib"
    ]
  )
