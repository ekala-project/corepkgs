# Networking configuration
# Handles basic network settings like hostname, domain, DNS
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.networking;

in

{
  options = {
    networking.hostName = mkOption {
      type = types.str;
      default = "ekaos";
      example = "myserver";
      description = ''
        The hostname of the system.

        This will be used to set /etc/hostname and will be included in /etc/hosts.
      '';
    };

    networking.domain = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "example.com";
      description = ''
        The domain name of the system.

        If set, the fully qualified domain name (FQDN) will be hostname.domain.
      '';
    };

    networking.nameservers = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "8.8.8.8"
        "8.8.4.4"
      ];
      description = ''
        List of nameservers to use for DNS resolution.

        These will be written to /etc/resolv.conf.
      '';
    };

    networking.search = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "example.com"
        "local"
      ];
      description = ''
        List of search domains for DNS resolution.
      '';
    };

    networking.resolvconf = {
      extraOptions = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "single-request"
          "edns0"
        ];
        description = ''
          Options to append to the resolv.conf options line.
          See resolv.conf(5) for available options.
        '';
      };

      dnsSingleRequest = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to use single-request option to avoid some AAAA lookup issues.";
      };

      dnsExtensionMechanism = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable EDNS0 extension mechanism.";
      };
    };

    networking.fqdn = mkOption {
      type = types.str;
      readOnly = true;
      default = if cfg.domain != null then "${cfg.hostName}.${cfg.domain}" else cfg.hostName;
      defaultText = literalExpression ''"''${networking.hostName}.''${networking.domain}"'';
      description = ''
        The fully qualified domain name (FQDN) of the system.

        Computed from hostName and domain. Read-only.
      '';
    };

    networking.hosts = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = { };
      example = literalExpression ''
        {
          "127.0.0.1" = [ "myhost" ];
          "192.168.1.10" = [ "server.example.com" "server" ];
        }
      '';
      description = ''
        Structured /etc/hosts entries.

        Keys are IP addresses, values are lists of hostnames.
        Merged with extraHosts and default localhost entries.
      '';
    };

    networking.extraHosts = mkOption {
      type = types.lines;
      default = "";
      example = ''
        192.168.1.100 server1.example.com server1
        192.168.1.101 server2.example.com server2
      '';
      description = ''
        Additional entries to add to /etc/hosts.
      '';
    };

    networking.enableIPv6 = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable IPv6 support.";
    };

    networking.proxy = {
      default = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "http://proxy.example.com:8080";
        description = ''
          Default proxy URL used for HTTP, HTTPS, and FTP.
          Sets the http_proxy, https_proxy, and ftp_proxy environment variables.
        '';
      };

      noProxy = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "127.0.0.1,localhost,.example.com";
        description = "Comma-separated list of domains/IPs that bypass the proxy.";
      };

      httpProxy = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "HTTP proxy URL. Overrides networking.proxy.default for HTTP.";
      };

      httpsProxy = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "HTTPS proxy URL. Overrides networking.proxy.default for HTTPS.";
      };
    };

    networking.hostId = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "a8c01e01";
      description = ''
        The 32-bit host ID of the machine, formatted as 8 hexadecimal characters.

        Required by ZFS for safe pool import. Generate with:
          head -c4 /dev/urandom | od -A none -t x4 | tr -d ' '
      '';
    };

    networking.usePredictableInterfaceNames = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to use predictable network interface names (e.g. enp0s3)
        instead of classic names (e.g. eth0).

        Uses systemd's predictable naming scheme based on firmware,
        topology, and device path information.
      '';
    };

    networking.useNetworkd = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to use systemd-networkd for network configuration
        instead of the scripted networking setup.
      '';
    };

    networking.tempAddresses = mkOption {
      type = types.enum [
        "default"
        "enabled"
        "disabled"
      ];
      default = "default";
      description = ''
        Whether to enable IPv6 Privacy Extensions (RFC 4941).

        - default: Use kernel default
        - enabled: Generate temporary addresses
        - disabled: Do not generate temporary addresses
      '';
    };

    networking.timeServers = mkOption {
      type = types.listOf types.str;
      default = [
        "0.pool.ntp.org"
        "1.pool.ntp.org"
        "2.pool.ntp.org"
        "3.pool.ntp.org"
      ];
      description = ''
        NTP servers used for time synchronization.
      '';
    };

    networking.localCommands = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Shell commands to execute after all network interfaces have
        been started. Useful for custom routing, tunnels, etc.
      '';
    };

    networking.useDHCP = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to use DHCP for network configuration.

        When true, enables automatic network configuration via DHCP.
        When false, you must configure interfaces manually.
      '';
    };

    networking.defaultGateway = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "192.168.1.1";
      description = ''
        The default gateway for IPv4 traffic.

        Only used when useDHCP is false.
      '';
    };

    networking.defaultGateway6 = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "fe80::1";
      description = ''
        The default gateway for IPv6 traffic.

        Only used when useDHCP is false.
      '';
    };
  };

  config = {
    # hostname and hosts are already configured in etc.nix,
    # but we ensure they use our values
    environment.etc."hostname".text = mkForce cfg.hostName;

    environment.etc."hosts".text = mkForce (
      let
        structuredHosts = concatStringsSep "\n" (
          mapAttrsToList (ip: names: "${ip} ${concatStringsSep " " names}") cfg.hosts
        );
      in
      ''
        # Generated by ekaos networking module
        127.0.0.1 localhost
        ::1 localhost
        127.0.1.1 ${cfg.fqdn} ${cfg.hostName}

        ${optionalString (structuredHosts != "") structuredHosts}
        ${cfg.extraHosts}
      ''
    );

    # Generate resolv.conf
    environment.etc."resolv.conf" = mkIf (cfg.nameservers != [ ]) {
      text =
        let
          resolvOptions =
            cfg.resolvconf.extraOptions
            ++ optional cfg.resolvconf.dnsSingleRequest "single-request"
            ++ optional cfg.resolvconf.dnsExtensionMechanism "edns0";
        in
        ''
          # Generated by ekaos networking module
          ${optionalString (cfg.search != [ ]) "search ${concatStringsSep " " cfg.search}"}
          ${concatMapStringsSep "\n" (ns: "nameserver ${ns}") cfg.nameservers}
          ${optionalString (resolvOptions != [ ]) "options ${concatStringsSep " " resolvOptions}"}
        '';
    };

    # Disable IPv6 via sysctl if requested
    boot.kernel.sysctl = mkMerge [
      (mkIf (!cfg.enableIPv6) {
        "net.ipv6.conf.all.disable_ipv6" = true;
        "net.ipv6.conf.default.disable_ipv6" = true;
      })
      (mkIf (cfg.tempAddresses != "default") {
        "net.ipv6.conf.all.use_tempaddr" = if cfg.tempAddresses == "enabled" then 2 else 0;
        "net.ipv6.conf.default.use_tempaddr" = if cfg.tempAddresses == "enabled" then 2 else 0;
      })
    ];

    # Set proxy environment variables
    environment.variables = mkMerge [
      (mkIf (cfg.proxy.default != null || cfg.proxy.httpProxy != null) {
        http_proxy = cfg.proxy.httpProxy or cfg.proxy.default;
      })
      (mkIf (cfg.proxy.default != null || cfg.proxy.httpsProxy != null) {
        https_proxy = cfg.proxy.httpsProxy or cfg.proxy.default;
      })
      (mkIf (cfg.proxy.noProxy != null) {
        no_proxy = cfg.proxy.noProxy;
      })
    ];

    # Add networking utilities
    environment.systemPackages = with pkgs; [
      iproute2
      iputils
      net-tools
    ];

    # Write /etc/hostid if networking.hostId is set
    environment.etc."hostid" = mkIf (cfg.hostId != null) {
      source = pkgs.runCommand "gen-hostid" { } ''
        ${pkgs.coreutils}/bin/printf "$(echo ${cfg.hostId} | ${pkgs.gnused}/bin/sed 's/\(..\)/\\x\1/g')" > $out
      '';
    };

    # Predictable interface names
    boot.kernelParams = mkIf (!cfg.usePredictableInterfaceNames) [
      "net.ifnames=0"
    ];

    # Set hostname during activation
    system.activationScripts.hostname = stringAfter [ "etc" ] ''
      # Set system hostname
      echo "Setting hostname to ${cfg.hostName}..."
      ${pkgs.net-tools}/bin/hostname "${cfg.hostName}"
    '';

    # Run local network commands after setup
    system.activationScripts.network-local-commands = mkIf (cfg.localCommands != "") (
      stringAfter
        [
          "etc"
          "hostname"
        ]
        ''
          echo "Running local network commands..."
          ${cfg.localCommands}
        ''
    );
  };
}
