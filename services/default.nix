# Service management system
# This provides a unified interface for defining services across different service managers
{
  pkgs ? import ../. { },
}:

let
  inherit (pkgs) lib;
  serviceLib = import ./lib/service-module.nix { inherit lib pkgs; };

  # Evaluate a service configuration
  evalServices =
    servicesConfig:
    let
      eval = lib.evalModules {
        modules = [
          {
            options.services = serviceLib.mkServicesOption;
            config.services = servicesConfig;
          }
        ];
      };
    in
    eval.config.services;

  # Build systemd user service files
  buildSystemdUserServices =
    servicesConfig:
    let
      services = evalServices servicesConfig;
    in
    serviceLib.mkSystemdUserServices services;

in
{
  inherit evalServices buildSystemdUserServices;

  # Export library functions
  lib = serviceLib;
}
