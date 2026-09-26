# Adios port of ekaos/modules/services/networking/unbound.nix.
# TODO(adios-cutover): command/args were internal options set by the legacy
# config; they are computed in impl, not user options.
# TODO(adios-cutover): forwardZones/stubZones/localZones used listOf
# (submodule ...); submodule validation lost, defaults (local zone
# type="static") re-applied via `or` fallbacks in impl.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Whether to enable the Unbound DNS recursive resolver.";
    };

    description = {
      type = types.string;
      default = "Unbound DNS Resolver";
      description = "Service description.";
    };

    user = {
      type = types.string;
      default = "unbound";
      description = "User to run Unbound as.";
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

    ports = {
      type = types.attrsOf types.any;
      default = { };
      description = "Port contracts for this service.";
    };

    package = {
      type = types.derivation;
      default = pkgs.unbound;
      description = "Unbound package to use.";
    };

    stateDir = {
      type = types.string;
      default = "/var/lib/unbound";
      description = "Directory for Unbound state (DNSSEC trust anchor, etc.).";
    };

    resolveLocalQueries = {
      type = types.bool;
      default = true;
      description = ''
        Whether to set the system resolver to use Unbound.
        When true, /etc/resolv.conf will point to 127.0.0.1.
      '';
    };

    settings = {
      options = {
        port = {
          type = types.int;
          default = 53;
          description = "Port for Unbound to listen on.";
        };

        listenAddresses = {
          type = types.listOf types.string;
          default = [ "127.0.0.1" ];
          description = "Addresses for Unbound to listen on.";
        };

        accessControl = {
          type = types.listOf types.string;
          default = [ "127.0.0.0/8 allow" ];
          description = ''
            Access control rules. Each entry is a CIDR/action pair.
            Actions: deny, refuse, allow, allow_snoop, deny_non_local, refuse_non_local.
          '';
        };

        enableDNSSEC = {
          type = types.bool;
          default = true;
          description = "Whether to enable DNSSEC validation using the root trust anchor.";
        };

        numThreads = {
          type = types.nullOr types.int;
          default = null;
          description = "Number of threads to use. null uses Unbound's default (1).";
        };

        forwardZones = {
          type = types.listOf types.attrs;
          default = [ ];
          description = ''
            Forward zones. Queries for these zones are forwarded to the
            specified upstream resolvers instead of being resolved recursively.
          '';
        };

        stubZones = {
          type = types.listOf types.attrs;
          default = [ ];
          description = ''
            Stub zones. Queries for these zones are sent directly to the
            specified authoritative server.
          '';
        };

        localZones = {
          type = types.listOf types.attrs;
          default = [ ];
          description = "Local zone overrides.";
        };

        remoteControl = {
          options = {
            enable = {
              type = types.bool;
              default = false;
              description = "Whether to enable unbound-control remote control.";
            };

            interface = {
              type = types.string;
              default = "127.0.0.1";
              description = "Interface for remote control.";
            };
          };
          description = "Remote control configuration.";
        };

        extraServerConfig = {
          type = types.string;
          default = "";
          description = "Extra configuration lines for the server section.";
        };

        extraConfig = {
          type = types.string;
          default = "";
          description = "Extra configuration appended to unbound.conf (outside server section).";
        };
      };
      description = "Unbound configuration.";
    };
  };

  inputs = {
    # TODO(adios-cutover): verify tree path once the networking batch lands
    # (legacy reads config.networking.dns.forwardZones, defined in
    # networking/dns-zones.nix).
    dnsZones.from = { root }: root.networking."dns-zones";
  };

  assertions = [
    {
      verify = { options }: (options.settings.port or 53) >= 0 && (options.settings.port or 53) <= 65535;
      explain =
        { options }: "unbound port must be 0-65535, got ${toString (options.settings.port or 53)}";
    }
    {
      verify =
        { options }:
        (options.settings.numThreads or null) == null || (options.settings.numThreads or 0) > 0;
      explain =
        { options }:
        "unbound numThreads must be positive, got ${toString (options.settings.numThreads or 0)}";
    }
  ];

  impl =
    { options, inputs }:
    if !options.enable then
      { }
    else
      let
        s = options.settings;
        port = s.port or 53;
        listenAddresses = s.listenAddresses or [ "127.0.0.1" ];
        remoteControl = s.remoteControl or { };

        dnsForwardZones = builtins.map (zone: {
          name = zone;
          forwardAddresses = [ (inputs.dnsZones.forwardZones or { }).${zone} ];
        }) (builtins.attrNames (inputs.dnsZones.forwardZones or { }));

        # Legacy list-merge: user zones ++ zones from networking.dns.
        mergedForwardZones = (s.forwardZones or [ ]) ++ dnsForwardZones;

        unboundConf = pkgs.writeText "unbound.conf" ''
          server:
              directory: "${options.stateDir}"
              username: ""
              chroot: ""
              pidfile: ""
              do-daemonize: no
              interface: ${builtins.concatStringsSep "\n    interface: " listenAddresses}
              port: ${toString port}
              ${builtins.concatStringsSep "\n    " (
                builtins.map (ac: "access-control: ${ac}") (s.accessControl or [ ])
              )}
              ${
                if (s.enableDNSSEC or true) then
                  ''
                    auto-trust-anchor-file: "${options.stateDir}/root.key"
                  ''
                else
                  ""
              }
              ${
                if (s.numThreads or null) != null then
                  ''
                    num-threads: ${toString s.numThreads}
                  ''
                else
                  ""
              }
              ${s.extraServerConfig or ""}

          ${builtins.concatStringsSep "\n" (
            builtins.map (zone: ''
              forward-zone:
                  name: "${zone.name}"
                  ${builtins.concatStringsSep "\n    " (
                    builtins.map (addr: "forward-addr: ${addr}") zone.forwardAddresses
                  )}
            '') mergedForwardZones
          )}

          ${builtins.concatStringsSep "\n" (
            builtins.map (zone: ''
              stub-zone:
                  name: "${zone.name}"
                  stub-addr: ${zone.stubAddr}
            '') (s.stubZones or [ ])
          )}

          ${builtins.concatStringsSep "\n" (
            builtins.map (zone: ''
              local-zone: "${zone.name}" ${zone.type or "static"}
            '') (s.localZones or [ ])
          )}

          ${
            if (remoteControl.enable or false) then
              ''
                remote-control:
                    control-enable: yes
                    control-interface: ${remoteControl.interface or "127.0.0.1"}
                    server-key-file: "${options.stateDir}/unbound_server.key"
                    server-cert-file: "${options.stateDir}/unbound_server.pem"
                    control-key-file: "${options.stateDir}/unbound_control.key"
                    control-cert-file: "${options.stateDir}/unbound_control.pem"
              ''
            else
              ""
          }

          ${s.extraConfig or ""}
        '';
      in
      {
        services.unbound = {
          inherit (options)
            enable
            description
            user
            restartPolicy
            ;
          command = "${options.package}/bin/unbound";
          args = [
            "-d"
            "-c"
            "${unboundConf}"
          ];
          settings = s // {
            forwardZones = mergedForwardZones;
          };
          ports = options.ports // {
            dns = {
              port = port;
              protocol = "udp";
              transport = "udp";
              internal = listenAddresses == [ "127.0.0.1" ];
              openFirewall = listenAddresses != [ "127.0.0.1" ];
            };
          };
          systemd = {
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
          }
          // options.systemd;
        };

        users.users.${options.user} = {
          isSystemUser = true;
          group = options.user;
          description = "Unbound DNS resolver user";
        };
        users.groups.${options.user} = { };

        # TODO(adios-cutover): legacy mkBefore priority lost; plain value.
        networking.nameservers = if (options.resolveLocalQueries or true) then [ "127.0.0.1" ] else [ ];

        environment.etc."unbound/unbound.conf".source = unboundConf;

        environment.systemPackages = [ options.package ];

        # TODO(adios-cutover): legacy ordering (after "etc" "users") lost; plain script.
        system.activationScripts.unbound = ''
          mkdir -p ${options.stateDir}
          chown ${options.user}:${options.user} ${options.stateDir}
          chmod 750 ${options.stateDir}

          ${
            if (s.enableDNSSEC or true) then
              ''
                # Initialize or update DNSSEC root trust anchor
                ${options.package}/bin/unbound-anchor -a ${options.stateDir}/root.key || true
                chown ${options.user}:${options.user} ${options.stateDir}/root.key
              ''
            else
              ""
          }

          ${
            if (remoteControl.enable or false) then
              ''
                # Generate remote control keys if not present
                if [ ! -f ${options.stateDir}/unbound_server.key ]; then
                  ${options.package}/bin/unbound-control-setup -d ${options.stateDir}
                  chown ${options.user}:${options.user} ${options.stateDir}/unbound_*.key ${options.stateDir}/unbound_*.pem
                fi
              ''
            else
              ""
          }
        '';
      };
}
