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

  # Build systemd system service files (for /etc/systemd/system)
  buildSystemdSystemServices =
    servicesConfig:
    let
      services = evalServices servicesConfig;
    in
    serviceLib.mkSystemdSystemServices services;

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

  # Build runit service directories (for /etc/sv)
  buildRunitServices =
    servicesConfig:
    let
      services = evalServices servicesConfig;
    in
    serviceLib.mkRunitServices services;

  # Build BSD rc.d service files (FreeBSD/NetBSD/DragonFly for /etc/rc.d or /usr/local/etc/rc.d)
  buildRcdServices =
    servicesConfig:
    let
      services = evalServices servicesConfig;
    in
    serviceLib.mkRcdServices services;

  # Build BSD rc.d service files (OpenBSD variant for /etc/rc.d)
  buildRcdServicesOpenBSD =
    servicesConfig:
    let
      services = evalServices servicesConfig;
    in
    serviceLib.mkRcdServicesOpenBSD services;

  # Build Docker image with runit supervision
  # Additional arguments:
  #   - name: Docker image name
  #   - tag: Docker image tag (default: "latest")
  #   - extraContents: Additional packages to include
  #   - exposedPorts: Ports to expose (e.g., ["8080/tcp" "9090/tcp"])
  #   - imageConfig: Additional Docker config
  #   - preStartCommands: Shell commands to run before starting runit
  buildRunitDockerImage =
    servicesConfig:
    {
      name,
      tag ? "latest",
      extraContents ? [ ],
      exposedPorts ? [ ],
      imageConfig ? { },
      preStartCommands ? "",
    }:
    let
      services = evalServices servicesConfig;
    in
    serviceLib.mkRunitDockerImage {
      inherit
        services
        name
        tag
        extraContents
        exposedPorts
        imageConfig
        preStartCommands
        ;
    };

in
{
  inherit
    evalServices
    buildSystemdUserServices
    buildSystemdSystemServices
    buildLaunchdUserAgents
    buildLaunchdDaemons
    buildRunitServices
    buildRcdServices
    buildRcdServicesOpenBSD
    buildRunitDockerImage
    ;

  # Export library functions
  lib = serviceLib;
}
