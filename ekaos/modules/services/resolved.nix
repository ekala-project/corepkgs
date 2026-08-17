# systemd-resolved DNS resolver daemon
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.resolved;

  toResolvedValue =
    v:
    if isBool v then
      (if v then "yes" else "no")
    else if isList v then
      concatStringsSep " " v
    else
      toString v;

  resolvedConf = pkgs.writeText "resolved.conf" (
    "[Resolve]\n"
    + concatStringsSep "\n" (
      mapAttrsToList (k: v: if v == null then "" else "${k}=${toResolvedValue v}") cfg.settings
    )
    + "\n"
  );

in

{
  options.services.resolved = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the systemd DNS resolver daemon (systemd-resolved).";
    };

    description = mkOption {
      type = types.str;
      default = "Network Name Resolution";
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
      default = "systemd-resolve";
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

    settings = mkOption {
      type = types.attrsOf (
        types.nullOr (
          types.oneOf [
            types.bool
            types.int
            types.str
            (types.listOf types.str)
          ]
        )
      );
      default = { };
      description = ''
        Settings for systemd-resolved written to /etc/systemd/resolved.conf.
        See resolved.conf(5) for all available options.
      '';
    };

    fallbackDns = mkOption {
      type = types.listOf types.str;
      default = [
        "1.1.1.1"
        "8.8.8.8"
        "1.0.0.1"
        "8.8.4.4"
      ];
      description = "Fallback DNS servers when no others are configured.";
    };

    dnssec = mkOption {
      type = types.enum [
        true
        false
        "allow-downgrade"
      ];
      default = false;
      description = ''
        Whether to enable DNSSEC validation.
        - true: enforce DNSSEC
        - false: disable DNSSEC
        - "allow-downgrade": validate when possible, permit unsigned otherwise
      '';
    };

    dnsOverTls = mkOption {
      type = types.enum [
        true
        false
        "opportunistic"
      ];
      default = false;
      description = ''
        Whether to use DNS-over-TLS.
        - true: require DNS-over-TLS
        - false: disable
        - "opportunistic": use when available
      '';
    };

    llmnr = mkOption {
      type = types.enum [
        true
        false
        "resolve"
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

  config = mkIf cfg.enable {
    # Merge structured options into settings
    services.resolved.settings = {
      DNS = mkDefault (config.networking.nameservers or [ ]);
      FallbackDNS = mkDefault cfg.fallbackDns;
      Domains = mkDefault (config.networking.search or [ ]);
      DNSSEC = mkDefault cfg.dnssec;
      DNSOverTLS = mkDefault cfg.dnsOverTls;
      LLMNR = mkDefault cfg.llmnr;
    };

    # Define the resolved service
    services.resolved = {
      command = "${config.systemd.package}/lib/systemd/systemd-resolved";
      args = [ ];

      systemd = {
        wantedBy = [ "sysinit.target" ];
        after = [ "systemd-networkd.service" ];
        before = [ "network-online.target" ];
      };
    };

    # Install resolved configuration
    environment.etc."systemd/resolved.conf".source = resolvedConf;

    # Point resolv.conf to the stub resolver
    environment.etc."resolv.conf".source = mkForce "/run/systemd/resolve/stub-resolv.conf";

    # Add resolve to NSS hosts database
    system.nssDatabases.hosts = mkOrder 501 [
      "resolve [!UNAVAIL=return]"
    ];

    # Create resolve user
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
      description = "systemd Resolver";
    };
    users.groups.${cfg.user} = { };

    # Ensure state directory exists
    system.activationScripts.resolved = stringAfter [ "etc" "users" ] ''
      mkdir -p /run/systemd/resolve
    '';

    environment.systemPackages = [ config.systemd.package ];
  };
}
