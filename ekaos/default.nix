# ekaos system builder
# Main entry point for building ekaos systems
#
# Usage (from a flake):
#
#   core-pkgs.lib.ekaosSystem {
#     system = "x86_64-linux";
#     modules = [ <extra adios modules> ];
#     overrides = {
#       options."/boot/kernel" = { kernelParams = [ "quiet" ]; };
#     };
#   };
#
{
  system,
  modules ? [ ],
  overrides ? { },
  extraConfig ? { },
  pkgs ? import ../. { inherit system; },
  lib ? pkgs.lib,
  adios,
  ...
}@args:

import ./eval-config.nix
  {
    inherit lib pkgs adios;
  }
  (
    {
      inherit modules overrides extraConfig;
    }
    // builtins.removeAttrs args [
      "system"
      "pkgs"
      "lib"
      "adios"
      "modules"
      "overrides"
      "extraConfig"
    ]
  )
