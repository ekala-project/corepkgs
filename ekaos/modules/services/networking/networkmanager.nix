# NetworkManager service module
# Provides automatic network configuration via NetworkManager
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.networking.networkmanager;

  # Generate NetworkManager.conf
  nmConf = pkgs.writeText "NetworkManager.conf" ''
    [main]
    plugins=keyfile
    ${optionalString (cfg.dns != "default") "dns=${cfg.dns}"}
    ${optionalString (cfg.unmanaged != [ ]) ''

      [keyfile]
      unmanaged-devices=${concatStringsSep ";" (map (d: "interface-name:${d}") cfg.unmanaged)}
    ''}

    ${optionalString cfg.wifi.enable ''
      [device]
      wifi.scan-rand-mac-address=${if cfg.wifi.macRandomization then "yes" else "no"}
    ''}

    ${cfg.extraConfig}
  '';

in

{
  options = {
    networking.networkmanager = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable NetworkManager for automatic network configuration.

          NetworkManager manages network connections via D-Bus and provides
          a unified interface for Ethernet, WiFi, and mobile broadband.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.networkmanager or (throw "networkmanager package not available in core-pkgs");
        defaultText = literalExpression "pkgs.networkmanager";
        description = "The NetworkManager package to use.";
      };

      dns = mkOption {
        type = types.enum [
          "default"
          "none"
          "systemd-resolved"
          "dnsmasq"
        ];
        default = "default";
        description = ''
          DNS resolution backend for NetworkManager.

          - default: NetworkManager manages /etc/resolv.conf directly
          - none: NetworkManager does not touch DNS
          - systemd-resolved: Use systemd-resolved
          - dnsmasq: Use dnsmasq as local resolver
        '';
      };

      unmanaged = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "lo"
          "docker0"
          "br-*"
        ];
        description = ''
          List of interface names (or patterns) that NetworkManager should not manage.
        '';
      };

      wifi = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to enable WiFi support in NetworkManager.";
        };

        macRandomization = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to randomize MAC address during WiFi scanning.";
        };

        backend = mkOption {
          type = types.enum [
            "wpa_supplicant"
            "iwd"
          ];
          default = "wpa_supplicant";
          description = "WiFi backend to use.";
        };
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Additional lines appended to NetworkManager.conf.";
      };
    };

    # Service interface options for the cross-platform service manager
    services.network-manager = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the NetworkManager service.";
      };

      description = mkOption {
        type = types.str;
        default = "NetworkManager";
        description = "Service description.";
      };

      command = mkOption {
        type = types.str;
        internal = true;
        description = "Command to run (set automatically).";
      };

      args = mkOption {
        type = types.listOf types.str;
        internal = true;
        default = [ ];
        description = "Command arguments (set automatically).";
      };

      user = mkOption {
        type = types.str;
        default = "root";
        description = "User to run service as.";
      };

      restartPolicy = mkOption {
        type = types.str;
        default = "always";
        description = "Restart policy.";
      };

      systemd = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Systemd-specific options.";
      };
    };
  };

  config = mkIf cfg.enable {
    # NetworkManager service
    services.network-manager = {
      enable = true;
      command = "${cfg.package}/bin/NetworkManager";
      args = [
        "--no-daemon"
        "--config=${nmConf}"
      ];
      user = "root";
      restartPolicy = "always";
      systemd = {
        after = [
          "dbus.service"
          "network-pre.target"
        ];
        wantedBy = [ "multi-user.target" ];
      };
    };

    # D-Bus is required for NetworkManager
    services.dbus.packages = [ cfg.package ];

    # Install NetworkManager config and utilities
    environment.etc."NetworkManager/NetworkManager.conf".source = nmConf;
    environment.systemPackages = [ cfg.package ];

    # Ensure NetworkManager does not conflict with manual networking
    networking.useDHCP = mkDefault false;

    # Add nm-online dispatcher to wait for network
    system.activationScripts.networkmanager = stringAfter [ "etc" "users" ] ''
      mkdir -p /etc/NetworkManager/system-connections
      mkdir -p /var/lib/NetworkManager
      chmod 700 /etc/NetworkManager/system-connections
    '';
  };
}
