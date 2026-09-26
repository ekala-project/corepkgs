# Adios port of ekaos/modules/services/networking/bind.nix.
# TODO(adios-cutover): command/args were internal options set by the legacy
# config; they are computed in impl, not user options.
# TODO(adios-cutover): zones used attrsOf (submodule ...) with per-zone
# defaults (type="master", masters=[], allowQuery/allowTransfer=null,
# extraConfig=""); submodule validation lost, defaults re-applied via
# `or` fallbacks in impl.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Whether to enable the BIND DNS server.";
    };

    description = {
      type = types.string;
      default = "BIND DNS Server";
      description = "Service description.";
    };

    user = {
      type = types.string;
      default = "named";
      description = "User to run BIND as.";
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
      default = pkgs.bind;
      description = "BIND package to use.";
    };

    directory = {
      type = types.string;
      default = "/run/named";
      description = "Working directory for BIND.";
    };

    settings = {
      options = {
        port = {
          type = types.int;
          default = 53;
          description = "Port for BIND to listen on.";
        };

        listenOn = {
          type = types.listOf types.string;
          default = [ "any" ];
          description = "IPv4 addresses to listen on.";
        };

        listenOnV6 = {
          type = types.listOf types.string;
          default = [ ];
          description = "IPv6 addresses to listen on.";
        };

        forwarders = {
          type = types.listOf types.string;
          default = [ ];
          description = "Upstream DNS servers for forwarding.";
        };

        forward = {
          type = types.enum "forward" [
            "first"
            "only"
          ];
          default = "first";
          description = ''
            Forwarding behavior.
            - first: Try forwarders first, then resolve recursively
            - only: Only use forwarders
          '';
        };

        recursion = {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable recursive queries.
            Disable for authoritative-only servers.
          '';
        };

        allowQuery = {
          type = types.nullOr types.string;
          default = null;
          description = "ACL for who can query this server. null uses BIND default.";
        };

        allowRecursion = {
          type = types.nullOr types.string;
          default = null;
          description = "ACL for who can make recursive queries.";
        };

        dnssecValidation = {
          type = types.bool;
          default = true;
          description = "Whether to enable DNSSEC validation.";
        };

        logSeverity = {
          type = types.enum "logSeverity" [
            "critical"
            "error"
            "warning"
            "notice"
            "info"
            "debug"
            "dynamic"
          ];
          default = "info";
          description = "Logging severity level.";
        };

        zones = {
          type = types.attrsOf types.attrs;
          default = { };
          description = "DNS zones to serve.";
        };

        extraOptions = {
          type = types.string;
          default = "";
          description = "Extra options for the options block.";
        };

        extraConfig = {
          type = types.string;
          default = "";
          description = "Extra configuration appended to named.conf.";
        };
      };
      description = "BIND configuration.";
    };
  };

  inputs = {
    # TODO(adios-cutover): verify tree path once the networking batch lands
    # (legacy reads config.networking.dns, defined in
    # networking/dns-zones.nix).
    dnsZones.from = { root }: root.networking."dns-zones";
    unbound.from = { root }: root.services.networking.unbound;
  };

  assertions = [
    {
      verify = { options }: (options.settings.port or 53) >= 0 && (options.settings.port or 53) <= 65535;
      explain = { options }: "bind port must be 0-65535, got ${toString (options.settings.port or 53)}";
    }
    {
      verify = { options, inputs }: !options.enable || !(inputs.unbound.enable or false);
      explain =
        { options, inputs }:
        "services.bind and services.unbound cannot both be enabled (port 53 conflict).";
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
        listenOn = s.listenOn or [ "any" ];
        listenOnV6 = s.listenOnV6 or [ ];
        forwarders = s.forwarders or [ ];
        zones = s.zones or { };

        dnsZones = inputs.dnsZones;
        autoZones =
          if (dnsZones.enable or false) then
            builtins.listToAttrs (
              builtins.map (domain: {
                name = domain;
                value = {
                  type = "master";
                  file = "${dnsZones.zoneDir}/${domain}.zone";
                  masters = [ ];
                  allowQuery = null;
                  allowTransfer = null;
                  extraConfig = "";
                };
              }) (builtins.attrNames (dnsZones.zones or { }))
            )
          else
            { };

        mergedZones = zones // autoZones;

        zoneConfigs = builtins.concatStringsSep "\n" (
          builtins.map (
            name:
            let
              zone = mergedZones.${name};
            in
            ''
              zone "${name}" {
                type ${zone.type or "master"};
                file "${zone.file}";
                ${
                  if (zone.masters or [ ]) != [ ] then
                    ''
                      masters { ${builtins.concatStringsSep "; " zone.masters}; };
                    ''
                  else
                    ""
                }
                ${
                  if (zone.allowQuery or null) != null then
                    ''
                      allow-query { ${zone.allowQuery}; };
                    ''
                  else
                    ""
                }
                ${
                  if (zone.allowTransfer or null) != null then
                    ''
                      allow-transfer { ${zone.allowTransfer}; };
                    ''
                  else
                    ""
                }
                ${zone.extraConfig or ""}
              };
            ''
          ) (builtins.attrNames mergedZones)
        );

        namedConf = pkgs.writeText "named.conf" ''
          # Generated by ekaos bind module

          options {
            directory "${options.directory}";
            listen-on port ${toString port} { ${builtins.concatStringsSep "; " listenOn}; };
            ${
              if listenOnV6 != [ ] then
                ''
                  listen-on-v6 port ${toString port} { ${builtins.concatStringsSep "; " listenOnV6}; };
                ''
              else
                ""
            }
            ${
              if forwarders != [ ] then
                ''
                  forwarders { ${builtins.concatStringsSep "; " forwarders}; };
                  forward ${s.forward or "first"};
                ''
              else
                ""
            }
            ${
              if (s.allowQuery or null) != null then
                ''
                  allow-query { ${s.allowQuery}; };
                ''
              else
                ""
            }
            ${
              if (s.allowRecursion or null) != null then
                ''
                  allow-recursion { ${s.allowRecursion}; };
                ''
              else
                ""
            }
            dnssec-validation ${if (s.dnssecValidation or true) then "auto" else "no"};
            recursion ${if (s.recursion or false) then "yes" else "no"};
            ${s.extraOptions or ""}
          };

          logging {
            channel default_log {
              stderr;
              severity ${s.logSeverity or "info"};
              print-time yes;
              print-category yes;
            };
            category default { default_log; };
          };

          ${zoneConfigs}

          ${s.extraConfig or ""}
        '';
      in
      {
        services.bind = {
          inherit (options) enable description restartPolicy;
          # named drops privileges itself after binding port 53.
          user = "root";
          command = "${options.package}/bin/named";
          args = [
            "-f"
            "-c"
            "${namedConf}"
            "-u"
            options.user
          ];
          settings = s // {
            zones = mergedZones;
          };
          ports = options.ports // {
            dns = {
              port = port;
              protocol = "udp";
              transport = "udp";
              internal = listenOn == [ "127.0.0.1" ];
              openFirewall = listenOn != [ "127.0.0.1" ];
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
          description = "BIND DNS server user";
        };
        users.groups.${options.user} = { };

        environment.etc."bind/named.conf".source = namedConf;

        environment.systemPackages = [ options.package ];

        # TODO(adios-cutover): legacy ordering (after "etc" "users") lost; plain script.
        system.activationScripts.bind = ''
          mkdir -p ${options.directory}
          chown ${options.user}:${options.user} ${options.directory}
          chmod 750 ${options.directory}

          # Generate rndc key if not present
          if [ ! -f /etc/bind/rndc.key ]; then
            ${options.package}/bin/rndc-confgen -a -c /etc/bind/rndc.key -u ${options.user} 2>/dev/null || true
          fi
        '';
      };
}
