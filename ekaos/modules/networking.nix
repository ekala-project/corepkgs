# Adios port of ekaos/modules/networking.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{
  types,
  lib,
  pkgs,
  ...
}:

{
  options = {
    # Legacy path: networking.hostName.
    hostName = {
      type = types.string;
      default = "ekaos";
      example = "myserver";
      description = ''
        The hostname of the system.

        This will be used to set /etc/hostname and will be included in /etc/hosts.
      '';
    };

    # Legacy path: networking.domain.
    domain = {
      type = types.nullOr types.string;
      default = null;
      example = "example.com";
      description = ''
        The domain name of the system.

        If set, the fully qualified domain name (FQDN) will be hostname.domain.
      '';
    };

    # Legacy path: networking.nameservers.
    nameservers = {
      type = types.listOf types.string;
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

    # Legacy path: networking.search.
    search = {
      type = types.listOf types.string;
      default = [ ];
      example = [
        "example.com"
        "local"
      ];
      description = ''
        List of search domains for DNS resolution.
      '';
    };

    # Legacy path: networking.resolvconf.extraOptions.
    resolvExtraOptions = {
      type = types.listOf types.string;
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

    # Legacy path: networking.resolvconf.dnsSingleRequest.
    resolvDnsSingleRequest = {
      type = types.bool;
      default = false;
      description = "Whether to use single-request option to avoid some AAAA lookup issues.";
    };

    # Legacy path: networking.resolvconf.dnsExtensionMechanism.
    resolvDnsExtensionMechanism = {
      type = types.bool;
      default = true;
      description = "Whether to enable EDNS0 extension mechanism.";
    };

    # Legacy path: networking.fqdn (read-only in legacy; readOnly dropped).
    fqdn = {
      type = types.string;
      defaultFunc =
        { options, ... }:
        if options.domain != null then "${options.hostName}.${options.domain}" else options.hostName;
      description = ''
        The fully qualified domain name (FQDN) of the system.

        Computed from hostName and domain.
      '';
    };

    # Legacy path: networking.hosts.
    hosts = {
      type = types.attrsOf (types.listOf types.string);
      default = { };
      example = {
        "127.0.0.1" = [ "myhost" ];
        "192.168.1.10" = [
          "server.example.com"
          "server"
        ];
      };
      description = ''
        Structured /etc/hosts entries.

        Keys are IP addresses, values are lists of hostnames.
        Merged with extraHosts and default localhost entries.
      '';
    };

    # Legacy path: networking.extraHosts.
    extraHosts = {
      type = types.string;
      default = "";
      example = ''
        192.168.1.100 server1.example.com server1
        192.168.1.101 server2.example.com server2
      '';
      description = ''
        Additional entries to add to /etc/hosts.
      '';
    };

    # Legacy path: networking.enableIPv6.
    enableIPv6 = {
      type = types.bool;
      default = true;
      description = "Whether to enable IPv6 support.";
    };

    # Legacy path: networking.proxy.default.
    proxyDefault = {
      type = types.nullOr types.string;
      default = null;
      example = "http://proxy.example.com:8080";
      description = ''
        Default proxy URL used for HTTP, HTTPS, and FTP.
        Sets the http_proxy, https_proxy, and ftp_proxy environment variables.
      '';
    };

    # Legacy path: networking.proxy.noProxy.
    proxyNoProxy = {
      type = types.nullOr types.string;
      default = null;
      example = "127.0.0.1,localhost,.example.com";
      description = "Comma-separated list of domains/IPs that bypass the proxy.";
    };

    # Legacy path: networking.proxy.httpProxy.
    proxyHttpProxy = {
      type = types.nullOr types.string;
      default = null;
      description = "HTTP proxy URL. Overrides networking.proxy.default for HTTP.";
    };

    # Legacy path: networking.proxy.httpsProxy.
    proxyHttpsProxy = {
      type = types.nullOr types.string;
      default = null;
      description = "HTTPS proxy URL. Overrides networking.proxy.default for HTTPS.";
    };

    # Legacy path: networking.hostId.
    hostId = {
      type = types.nullOr types.string;
      default = null;
      example = "a8c01e01";
      description = ''
        The 32-bit host ID of the machine, formatted as 8 hexadecimal characters.

        Required by ZFS for safe pool import.
      '';
    };

    # Legacy path: networking.usePredictableInterfaceNames.
    usePredictableInterfaceNames = {
      type = types.bool;
      default = true;
      description = ''
        Whether to use predictable network interface names (e.g. enp0s3)
        instead of classic names (e.g. eth0).
      '';
    };

    # Legacy path: networking.useNetworkd.
    useNetworkd = {
      type = types.bool;
      default = false;
      description = ''
        Whether to use systemd-networkd for network configuration
        instead of the scripted networking setup.
      '';
    };

    # Legacy path: networking.tempAddresses.
    tempAddresses = {
      type = types.enum "ipv6TempAddresses" [
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

    # Legacy path: networking.timeServers.
    timeServers = {
      type = types.listOf types.string;
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

    # Legacy path: networking.localCommands.
    localCommands = {
      type = types.string;
      default = "";
      description = ''
        Shell commands to execute after all network interfaces have
        been started. Useful for custom routing, tunnels, etc.
      '';
    };

    # Legacy path: networking.useDHCP.
    useDHCP = {
      type = types.bool;
      default = true;
      description = ''
        Whether to use DHCP for network configuration.

        When true, enables automatic network configuration via DHCP.
        When false, you must configure interfaces manually.
      '';
    };

    # Legacy path: networking.defaultGateway.
    defaultGateway = {
      type = types.nullOr types.string;
      default = null;
      example = "192.168.1.1";
      description = ''
        The default gateway for IPv4 traffic.

        Only used when useDHCP is false.
      '';
    };

    # Legacy path: networking.defaultGateway6.
    defaultGateway6 = {
      type = types.nullOr types.string;
      default = null;
      example = "fe80::1";
      description = ''
        The default gateway for IPv6 traffic.

        Only used when useDHCP is false.
      '';
    };
  };

  impl =
    { options, ... }:
    lib.merge.attrs.recursively {
      mutators = [
        {
          # TODO(adios-cutover): priority lost (was mkForce).
          environment.etc."hostname".text = options.hostName;

          # TODO(adios-cutover): priority lost (was mkForce).
          environment.etc."hosts".text =
            let
              structuredHosts = builtins.concatStringsSep "\n" (
                builtins.map (ip: "${ip} ${builtins.concatStringsSep " " options.hosts.${ip}}") (
                  builtins.attrNames options.hosts
                )
              );
            in
            ''
              # Generated by ekaos networking module
              127.0.0.1 localhost
              ::1 localhost
              127.0.1.1 ${options.fqdn} ${options.hostName}

              ${if structuredHosts != "" then structuredHosts else ""}
              ${options.extraHosts}
            '';

          # Add networking utilities.
          environment.systemPackages = with pkgs; [
            iproute2
            iputils
            net-tools
          ];

          # TODO(adios-cutover): stringAfter [ "etc" ] ordering dropped.
          system.activationScripts.hostname = ''
            # Set system hostname
            echo "Setting hostname to ${options.hostName}..."
            ${pkgs.net-tools}/bin/hostname "${options.hostName}"
          '';
        }

        (
          if options.nameservers != [ ] then
            {
              environment.etc."resolv.conf".text =
                let
                  resolvOptions =
                    options.resolvExtraOptions
                    ++ (if options.resolvDnsSingleRequest then [ "single-request" ] else [ ])
                    ++ (if options.resolvDnsExtensionMechanism then [ "edns0" ] else [ ]);
                in
                ''
                  # Generated by ekaos networking module
                  ${if options.search != [ ] then "search ${builtins.concatStringsSep " " options.search}" else ""}
                  ${builtins.concatStringsSep "\n" (builtins.map (ns: "nameserver ${ns}") options.nameservers)}
                  ${if resolvOptions != [ ] then "options ${builtins.concatStringsSep " " resolvOptions}" else ""}
                '';
            }
          else
            { }
        )

        (
          if !options.enableIPv6 then
            {
              boot.kernel.sysctl = {
                "net.ipv6.conf.all.disable_ipv6" = true;
                "net.ipv6.conf.default.disable_ipv6" = true;
              };
            }
          else
            { }
        )

        (
          if options.tempAddresses != "default" then
            {
              boot.kernel.sysctl = {
                "net.ipv6.conf.all.use_tempaddr" = if options.tempAddresses == "enabled" then 2 else 0;
                "net.ipv6.conf.default.use_tempaddr" = if options.tempAddresses == "enabled" then 2 else 0;
              };
            }
          else
            { }
        )

        (
          if options.proxyDefault != null || options.proxyHttpProxy != null then
            {
              environment.variables.http_proxy = options.proxyHttpProxy or options.proxyDefault;
            }
          else
            { }
        )

        (
          if options.proxyDefault != null || options.proxyHttpsProxy != null then
            {
              environment.variables.https_proxy = options.proxyHttpsProxy or options.proxyDefault;
            }
          else
            { }
        )

        (
          if options.proxyNoProxy != null then
            {
              environment.variables.no_proxy = options.proxyNoProxy;
            }
          else
            { }
        )

        (
          if options.hostId != null then
            {
              environment.etc."hostid".source = pkgs.runCommand "gen-hostid" { } ''
                ${pkgs.coreutils}/bin/printf "$(echo ${options.hostId} | ${pkgs.sed}/bin/sed 's/\(..\)/\\x\1/g')" > $out
              '';
            }
          else
            { }
        )

        (
          if !options.usePredictableInterfaceNames then
            {
              boot.kernelParams = [
                "net.ifnames=0"
              ];
            }
          else
            { }
        )

        (
          if options.localCommands != "" then
            {
              # TODO(adios-cutover): stringAfter [ "etc" "hostname" ] ordering dropped.
              system.activationScripts.network-local-commands = ''
                echo "Running local network commands..."
                ${options.localCommands}
              '';
            }
          else
            { }
        )
      ];
    };
}
