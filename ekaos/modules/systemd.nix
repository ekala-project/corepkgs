# Systemd integration for ekaos
# Consumes services.* definitions and generates systemd unit files
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  # Import the services library
  servicesLib = import ../../services/lib/service-module.nix { inherit lib pkgs; };

  # Only consume services.* namespace for cross-platform service translation
  # systemd.services.* is for direct systemd-specific configuration (raw units, etc.)
  # and is not translated through the services library
  crossPlatformServices = config.services;

  # Generate systemd unit files from cross-platform service definitions
  systemdUnits = servicesLib.mkSystemdSystemServices crossPlatformServices;

  # Combine all unit files into /etc/systemd/system
  systemdEtcDir = pkgs.runCommand "systemd-etc" { } ''
    mkdir -p $out/systemd/system

    # Copy all generated unit files
    ${concatMapStringsSep "\n" (name: ''
      cp ${systemdUnits.${name}}/*.service $out/systemd/system/ || true
    '') (attrNames systemdUnits)}
  '';

in

{
  options = {
    # No options defined here - service modules define their own options
    # at services.* or systemd.services.* as needed

    systemd.package = mkOption {
      type = types.package;
      default = pkgs.systemd;
      description = "The systemd package to use.";
    };

    systemd.defaultTarget = mkOption {
      type = types.str;
      default = "multi-user.target";
      description = "The default systemd target to boot into.";
    };
  };

  config = {
    # Add systemd units to /etc
    environment.etc = mkMerge [
      # Copy systemd unit files
      (listToAttrs (
        map (
          name:
          nameValuePair "systemd/system/${name}.service" {
            source = "${systemdUnits.${name}}/${name}.service";
          }
        ) (attrNames systemdUnits)
      ))

      # Default systemd configuration
      {
        "systemd/system.conf".text = ''
          [Manager]
          DefaultTimeoutStartSec=90s
          DefaultTimeoutStopSec=90s
        '';
      }

      # Create symlinks for essential systemd targets
      {
        "systemd/system/multi-user.target".source =
          "${config.systemd.package}/lib/systemd/system/multi-user.target";
        "systemd/system/sysinit.target".source =
          "${config.systemd.package}/lib/systemd/system/sysinit.target";
        "systemd/system/basic.target".source = "${config.systemd.package}/lib/systemd/system/basic.target";
        "systemd/system/sockets.target".source =
          "${config.systemd.package}/lib/systemd/system/sockets.target";
        "systemd/system/timers.target".source =
          "${config.systemd.package}/lib/systemd/system/timers.target";
        "systemd/system/paths.target".source = "${config.systemd.package}/lib/systemd/system/paths.target";
        "systemd/system/local-fs.target".source =
          "${config.systemd.package}/lib/systemd/system/local-fs.target";
        "systemd/system/remote-fs.target".source =
          "${config.systemd.package}/lib/systemd/system/remote-fs.target";
        "systemd/system/default.target".source =
          "${config.systemd.package}/lib/systemd/system/${config.systemd.defaultTarget}";
      }
    ];

    # No need to define systemd.services here - individual modules
    # define their own services at services.* or systemd.services.* as needed
  };
}
