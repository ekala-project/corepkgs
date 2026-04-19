# Systemd integration for ekaos
# Leverages the existing services/ infrastructure
{ config, lib, pkgs, ... }:

with lib;

let
  # Import the services library
  servicesLib = import ../services/lib/service-module.nix { inherit lib pkgs; };

  # Generate systemd unit files from service definitions
  systemdUnits = servicesLib.mkSystemdSystemServices config.systemd.services;

  # Combine all unit files into /etc/systemd/system
  systemdEtcDir = pkgs.runCommand "systemd-etc" {} ''
    mkdir -p $out/systemd/system

    # Copy all generated unit files
    ${concatMapStringsSep "\n" (name: ''
      cp ${systemdUnits.${name}}/*.service $out/systemd/system/ || true
    '') (attrNames systemdUnits)}
  '';

in

{
  options = {
    systemd.services = mkOption {
      type = types.attrsOf (types.submodule (import ../services/lib/options.nix { inherit lib; }).commonOptions);
      default = {};
      description = ''
        Systemd services to run on the system.

        These use the ekaos unified service interface and are
        automatically translated to systemd unit files.
      '';
      example = literalExpression ''
        {
          myservice = {
            enable = true;
            description = "My Service";
            command = "''${pkgs.mypackage}/bin/myservice";
            restartPolicy = "always";
          };
        }
      '';
    };

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
      (listToAttrs (map (name: nameValuePair
        "systemd/system/${name}.service"
        { source = "${systemdUnits.${name}}/${name}.service"; }
      ) (attrNames systemdUnits)))

      # Default systemd configuration
      {
        "systemd/system.conf".text = ''
          [Manager]
          DefaultTimeoutStartSec=90s
          DefaultTimeoutStopSec=90s
        '';
      }
    ];

    # Essential systemd targets and services
    systemd.services = {
      # Minimal set of services for a bootable system
      # More can be added by the user or by other modules
    };
  };
}
