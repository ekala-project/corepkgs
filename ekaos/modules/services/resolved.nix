# Adios port of ekaos/modules/services/resolved.nix.
# TODO(adios-cutover): command/args were internal options set by the legacy
# config; they are computed in impl, not user options.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Whether to enable the systemd DNS resolver daemon (systemd-resolved).";
    };

    description = {
      type = types.string;
      default = "Network Name Resolution";
      description = "Service description.";
    };

    user = {
      type = types.string;
      default = "systemd-resolve";
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

    settings = {
      type = types.attrsOf (
        types.nullOr (
          types.union [
            types.bool
            types.int
            types.string
            (types.listOf types.string)
          ]
        )
      );
      default = { };
      description = ''
        Settings for systemd-resolved written to /etc/systemd/resolved.conf.
        See resolved.conf(5) for all available options.
      '';
    };

    fallbackDns = {
      type = types.listOf types.string;
      default = [
        "1.1.1.1"
        "8.8.8.8"
        "1.0.0.1"
        "8.8.4.4"
      ];
      description = "Fallback DNS servers when no others are configured.";
    };

    dnssec = {
      type = types.union [
        types.bool
        (types.enum "dnssec" [ "allow-downgrade" ])
      ];
      default = false;
      description = ''
        Whether to enable DNSSEC validation.
        - true: enforce DNSSEC
        - false: disable DNSSEC
        - "allow-downgrade": validate when possible, permit unsigned otherwise
      '';
    };

    dnsOverTls = {
      type = types.union [
        types.bool
        (types.enum "dnsOverTls" [ "opportunistic" ])
      ];
      default = false;
      description = ''
        Whether to use DNS-over-TLS.
        - true: require DNS-over-TLS
        - false: disable
        - "opportunistic": use when available
      '';
    };

    llmnr = {
      type = types.union [
        types.bool
        (types.enum "llmnr" [ "resolve" ])
      ];
      default = true;
      description = ''
        Whether to enable Link-Local Multicast Name Resolution.
        - true: enable both responding and resolving
        - false: disable
        - "resolve": only resolve, don't respond
      '';
    };
  };

  inputs = {
    networking.from = { root }: root.networking;
    # TODO(adios-cutover): verify leaf path once the service-managers batch
    # lands (legacy reads config.systemd.package).
    systemd.from = { root }: root."service-managers".systemd;
  };

  impl =
    { options, inputs }:
    if !options.enable then
      { }
    else
      let
        toResolvedValue =
          v:
          if builtins.isBool v then
            (if v then "yes" else "no")
          else if builtins.isList v then
            builtins.concatStringsSep " " v
          else
            toString v;

        mergedSettings = {
          # TODO(adios-cutover): legacy mkDefault priority lost; user settings
          # win on conflict, approximating mkDefault semantics.
          DNS = inputs.networking.nameservers or [ ];
          FallbackDNS = options.fallbackDns;
          Domains = inputs.networking.search or [ ];
          DNSSEC = options.dnssec;
          DNSOverTLS = options.dnsOverTls;
          LLMNR = options.llmnr;
        }
        // options.settings;

        resolvedConf = pkgs.writeText "resolved.conf" (
          "[Resolve]\n"
          + builtins.concatStringsSep "\n" (
            builtins.map (
              k:
              let
                v = mergedSettings.${k};
              in
              if v == null then "" else "${k}=${toResolvedValue v}"
            ) (builtins.attrNames mergedSettings)
          )
          + "\n"
        );
      in
      {
        services.resolved = {
          inherit (options)
            enable
            description
            user
            restartPolicy
            ;
          command = "${inputs.systemd.package}/lib/systemd/systemd-resolved";
          args = [ ];
          settings = mergedSettings;
          systemd = {
            wantedBy = [ "sysinit.target" ];
            after = [ "systemd-networkd.service" ];
            before = [ "network-online.target" ];
          }
          // options.systemd;
        };

        environment.etc."systemd/resolved.conf".source = resolvedConf;

        # TODO(adios-cutover): legacy mkForce priority lost; plain value.
        environment.etc."resolv.conf".source = "/run/systemd/resolve/stub-resolv.conf";

        # TODO(adios-cutover): legacy mkOrder priority lost; plain value.
        system.nssDatabases.hosts = [
          "resolve [!UNAVAIL=return]"
        ];

        users.users.${options.user} = {
          isSystemUser = true;
          group = options.user;
          description = "systemd Resolver";
        };
        users.groups.${options.user} = { };

        # TODO(adios-cutover): legacy ordering (after "etc" "users") lost; plain script.
        system.activationScripts.resolved = ''
          mkdir -p /run/systemd/resolve
        '';

        environment.systemPackages = [ inputs.systemd.package ];
      };
}
