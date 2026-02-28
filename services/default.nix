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

  # Build launchd user agent plist files (for ~/Library/LaunchAgents)
  buildLaunchdUserAgents =
    servicesConfig:
    let
      services = evalServices servicesConfig;
    in
    serviceLib.mkLaunchdUserAgents services;

  # Build launchd daemon plist files (for /Library/LaunchDaemons)
  buildLaunchdDaemons =
    servicesConfig:
    let
      services = evalServices servicesConfig;
    in
    serviceLib.mkLaunchdDaemons services;

in
{
  inherit
    evalServices
    buildSystemdUserServices
    buildLaunchdUserAgents
    buildLaunchdDaemons
    ;

  # Export library functions
  lib = serviceLib;
}
