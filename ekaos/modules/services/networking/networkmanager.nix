# Adios port of ekaos/modules/services/networking/networkmanager.nix.
#
# The legacy module declares two namespaces (networking.networkmanager and
# services.network-manager); both are modelled as sub-option groups here and
# impl re-nests them into the legacy config shape.
# TODO(adios-cutover): command/args of services.network-manager were internal
# options set by the legacy config; they are computed in impl.
{ types, pkgs, ... }:

{
  options = {
    networkmanager = {
      options = {
        enable = {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable NetworkManager for automatic network configuration.

            NetworkManager manages network connections via D-Bus and provides
            a unified interface for Ethernet, WiFi, and mobile broadband.
          '';
        };

        package = {
          type = types.derivation;
          default = pkgs.networkmanager or (throw "networkmanager package not available in core-pkgs");
          description = "The NetworkManager package to use.";
        };

        dns = {
          type = types.enum "dns" [
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

        unmanaged = {
          type = types.listOf types.string;
          default = [ ];
          description = ''
            List of interface names (or patterns) that NetworkManager should not manage.
          '';
        };

        wifi = {
          options = {
            enable = {
              type = types.bool;
              default = true;
              description = "Whether to enable WiFi support in NetworkManager.";
            };

            macRandomization = {
              type = types.bool;
              default = true;
              description = "Whether to randomize MAC address during WiFi scanning.";
            };

            backend = {
              type = types.enum "backend" [
                "wpa_supplicant"
                "iwd"
              ];
              default = "wpa_supplicant";
              description = "WiFi backend to use.";
            };
          };
          description = "WiFi configuration.";
        };

        extraConfig = {
          type = types.string;
          default = "";
          description = "Additional lines appended to NetworkManager.conf.";
        };
      };
      description = "NetworkManager networking options.";
    };

    service = {
      options = {
        enable = {
          type = types.bool;
          default = false;
          description = "Whether to enable the NetworkManager service.";
        };

        description = {
          type = types.string;
          default = "NetworkManager";
          description = "Service description.";
        };

        user = {
          type = types.string;
          default = "root";
          description = "User to run service as.";
        };

        restartPolicy = {
          type = types.string;
          default = "always";
          description = "Restart policy.";
        };

        systemd = {
          type = types.attrsOf types.any;
          default = { };
          description = "Systemd-specific options.";
        };
      };
      description = "NetworkManager service interface options.";
    };
  };

  impl =
    { options, ... }:
    if !(options.networkmanager.enable or false) then
      { }
    else
      let
        nm = options.networkmanager;
        svc = options.service or { };
        wifi = nm.wifi or { };

        nmConf = pkgs.writeText "NetworkManager.conf" ''
          [main]
          plugins=keyfile
          ${if (nm.dns or "default") != "default" then "dns=${nm.dns}" else ""}
          ${
            if (nm.unmanaged or [ ]) != [ ] then
              ''
                [keyfile]
                unmanaged-devices=${
                  builtins.concatStringsSep ";" (builtins.map (d: "interface-name:${d}") nm.unmanaged)
                }
              ''
            else
              ""
          }

          ${
            if (wifi.enable or true) then
              ''
                [device]
                wifi.scan-rand-mac-address=${if (wifi.macRandomization or true) then "yes" else "no"}
              ''
            else
              ""
          }

          ${nm.extraConfig or ""}
        '';
      in
      {
        services.network-manager = {
          enable = true;
          description = svc.description or "NetworkManager";
          command = "${nm.package}/bin/NetworkManager";
          args = [
            "--no-daemon"
            "--config=${nmConf}"
          ];
          user = svc.user or "root";
          restartPolicy = svc.restartPolicy or "always";
          systemd = {
            after = [
              "dbus.service"
              "network-pre.target"
            ];
            wantedBy = [ "multi-user.target" ];
          }
          // (svc.systemd or { });
        };

        services.dbus.packages = [ nm.package ];

        environment.etc."NetworkManager/NetworkManager.conf".source = nmConf;
        environment.systemPackages = [ nm.package ];

        # TODO(adios-cutover): legacy mkDefault priority lost; plain value.
        networking.useDHCP = false;

        # TODO(adios-cutover): legacy ordering (after "etc" "users") lost; plain script.
        system.activationScripts.networkmanager = ''
          mkdir -p /etc/NetworkManager/system-connections
          mkdir -p /var/lib/NetworkManager
          chmod 700 /etc/NetworkManager/system-connections
        '';
      };
}
