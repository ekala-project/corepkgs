# Unbound DNS recursive resolver
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.unbound;
  dnsCfg = config.networking.dns;

  # Generate unbound.conf
  unboundConf = pkgs.writeText "unbound.conf" ''
    server:
        directory: "${cfg.stateDir}"
        username: ""
        chroot: ""
        pidfile: ""
        do-daemonize: no
        interface: ${concatStringsSep "\n    interface: " cfg.settings.listenAddresses}
        port: ${toString cfg.settings.port}
        ${concatMapStringsSep "\n    " (ac: "access-control: ${ac}") cfg.settings.accessControl}
        ${optionalString cfg.settings.enableDNSSEC ''
          auto-trust-anchor-file: "${cfg.stateDir}/root.key"
        ''}
        ${optionalString (cfg.settings.numThreads != null) ''
          num-threads: ${toString cfg.settings.numThreads}
        ''}
        ${cfg.settings.extraServerConfig}

    ${concatMapStringsSep "\n" (zone: ''
      forward-zone:
          name: "${zone.name}"
          ${concatMapStringsSep "\n    " (addr: "forward-addr: ${addr}") zone.forwardAddresses}
    '') cfg.settings.forwardZones}

    ${concatMapStringsSep "\n" (zone: ''
      stub-zone:
          name: "${zone.name}"
          stub-addr: ${zone.stubAddr}
    '') cfg.settings.stubZones}

    ${concatMapStringsSep "\n" (zone: ''
      local-zone: "${zone.name}" ${zone.type}
    '') cfg.settings.localZones}

    ${optionalString cfg.settings.remoteControl.enable ''
      remote-control:
          control-enable: yes
          control-interface: ${cfg.settings.remoteControl.interface}
          server-key-file: "${cfg.stateDir}/unbound_server.key"
          server-cert-file: "${cfg.stateDir}/unbound_server.pem"
          control-key-file: "${cfg.stateDir}/unbound_control.key"
          control-cert-file: "${cfg.stateDir}/unbound_control.pem"
    ''}

    ${cfg.settings.extraConfig}
  '';

  # Build forward zones from networking.dns.forwardZones
  dnsForwardZones = mapAttrsToList (zone: addr: {
    name = zone;
    forwardAddresses = [ addr ];
  }) (dnsCfg.forwardZones or { });

in

{
  options.services.unbound = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the Unbound DNS recursive resolver.";
    };

    description = mkOption {
      type = types.str;
      default = "Unbound DNS Resolver";
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
      default = "unbound";
      description = "User to run Unbound as.";
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

    ports = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Port contracts for this service.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.unbound;
      description = "Unbound package to use.";
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/unbound";
      description = "Directory for Unbound state (DNSSEC trust anchor, etc.).";
    };

    resolveLocalQueries = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to set the system resolver to use Unbound.
        When true, /etc/resolv.conf will point to 127.0.0.1.
      '';
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 53;
            description = "Port for Unbound to listen on.";
          };

          listenAddresses = mkOption {
            type = types.listOf types.str;
            default = [ "127.0.0.1" ];
            example = [
              "0.0.0.0"
              "::0"
            ];
            description = "Addresses for Unbound to listen on.";
          };

          accessControl = mkOption {
            type = types.listOf types.str;
            default = [ "127.0.0.0/8 allow" ];
            example = [
              "127.0.0.0/8 allow"
              "10.0.0.0/8 allow"
              "::1/128 allow"
            ];
            description = ''
              Access control rules. Each entry is a CIDR/action pair.
              Actions: deny, refuse, allow, allow_snoop, deny_non_local, refuse_non_local.
            '';
          };

          enableDNSSEC = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to enable DNSSEC validation using the root trust anchor.";
          };

          numThreads = mkOption {
            type = types.nullOr types.ints.positive;
            default = null;
            example = 4;
            description = "Number of threads to use. null uses Unbound's default (1).";
          };

          forwardZones = mkOption {
            type = types.listOf (
              types.submodule {
                options = {
                  name = mkOption {
                    type = types.str;
                    example = ".";
                    description = "Zone name. Use \".\" for all queries.";
                  };
                  forwardAddresses = mkOption {
                    type = types.listOf types.str;
                    example = [
                      "1.1.1.1"
                      "8.8.8.8"
                    ];
                    description = "Upstream resolver addresses to forward to.";
                  };
                };
              }
            );
            default = [ ];
            description = ''
              Forward zones. Queries for these zones are forwarded to the
              specified upstream resolvers instead of being resolved recursively.
            '';
          };

          stubZones = mkOption {
            type = types.listOf (
              types.submodule {
                options = {
                  name = mkOption {
                    type = types.str;
                    description = "Stub zone name.";
                  };
                  stubAddr = mkOption {
                    type = types.str;
                    description = "Address of the authoritative server for this zone.";
                  };
                };
              }
            );
            default = [ ];
            description = ''
              Stub zones. Queries for these zones are sent directly to the
              specified authoritative server.
            '';
          };

          localZones = mkOption {
            type = types.listOf (
              types.submodule {
                options = {
                  name = mkOption {
                    type = types.str;
                    description = "Local zone name.";
                  };
                  type = mkOption {
                    type = types.enum [
                      "static"
                      "deny"
                      "refuse"
                      "redirect"
                      "transparent"
                      "nodefault"
                      "typetransparent"
                      "inform"
                      "inform_deny"
                      "always_transparent"
                      "always_refuse"
                      "always_nxdomain"
                    ];
                    default = "static";
                    description = "Local zone type.";
                  };
                };
              }
            );
            default = [ ];
            description = "Local zone overrides.";
          };

          remoteControl = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "Whether to enable unbound-control remote control.";
            };

            interface = mkOption {
              type = types.str;
              default = "127.0.0.1";
              description = "Interface for remote control.";
            };
          };

          extraServerConfig = mkOption {
            type = types.lines;
            default = "";
            description = "Extra configuration lines for the server section.";
          };

          extraConfig = mkOption {
            type = types.lines;
            default = "";
            description = "Extra configuration appended to unbound.conf (outside server section).";
          };
        };
      };
      default = { };
      description = "Unbound configuration.";
    };
  };

  config = mkIf cfg.enable {
    # Merge forward zones from networking.dns.forwardZones
    services.unbound.settings.forwardZones = dnsForwardZones;

    # Define the Unbound service
    services.unbound = {
      command = "${cfg.package}/bin/unbound";
      args = [
        "-d"
        "-c"
        "${unboundConf}"
      ];
      restartPolicy = "always";

      ports.dns = {
        port = cfg.settings.port;
        protocol = "udp";
        transport = "udp";
        internal = cfg.settings.listenAddresses == [ "127.0.0.1" ];
        openFirewall = cfg.settings.listenAddresses != [ "127.0.0.1" ];
      };

      systemd = {
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
      };
    };

    # Create unbound user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
      description = "Unbound DNS resolver user";
    };
    users.groups.${cfg.user} = { };

    # Set system resolver to use Unbound
    networking.nameservers = mkIf cfg.resolveLocalQueries (mkBefore [ "127.0.0.1" ]);

    # Install configuration
    environment.etc."unbound/unbound.conf".source = unboundConf;

    # Add unbound tools to system packages
    environment.systemPackages = [ cfg.package ];

    # Initialize state directory and DNSSEC trust anchor
    system.activationScripts.unbound = stringAfter [ "etc" "users" ] ''
      mkdir -p ${cfg.stateDir}
      chown ${cfg.user}:${cfg.user} ${cfg.stateDir}
      chmod 750 ${cfg.stateDir}

      ${optionalString cfg.settings.enableDNSSEC ''
        # Initialize or update DNSSEC root trust anchor
        ${cfg.package}/bin/unbound-anchor -a ${cfg.stateDir}/root.key || true
        chown ${cfg.user}:${cfg.user} ${cfg.stateDir}/root.key
      ''}

      ${optionalString cfg.settings.remoteControl.enable ''
        # Generate remote control keys if not present
        if [ ! -f ${cfg.stateDir}/unbound_server.key ]; then
          ${cfg.package}/bin/unbound-control-setup -d ${cfg.stateDir}
          chown ${cfg.user}:${cfg.user} ${cfg.stateDir}/unbound_*.key ${cfg.stateDir}/unbound_*.pem
        fi
      ''}
    '';
  };
}
