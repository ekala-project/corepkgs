# Network Address Translation (NAT/masquerading)
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.networking.nat;

  # Port forwarding submodule
  forwardPortOpts = {
    options = {
      sourcePort = mkOption {
        type = types.either types.port (
          types.submodule {
            options = {
              from = mkOption {
                type = types.port;
                description = "Start of port range.";
              };
              to = mkOption {
                type = types.port;
                description = "End of port range.";
              };
            };
          }
        );
        description = "Source port or port range to forward.";
      };

      destination = mkOption {
        type = types.str;
        example = "192.168.1.10:80";
        description = "Destination address:port to forward to.";
      };

      proto = mkOption {
        type = types.enum [
          "tcp"
          "udp"
        ];
        default = "tcp";
        description = "Protocol for the port forward.";
      };

      loopbackIPs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "IPs for which hairpin NAT is set up.";
      };
    };
  };

  # Generate nftables NAT rules
  natRules =
    let
      forwardRules = concatMapStringsSep "\n" (
        fwd:
        let
          sport =
            if builtins.isInt fwd.sourcePort then
              toString fwd.sourcePort
            else
              "${toString fwd.sourcePort.from}-${toString fwd.sourcePort.to}";
        in
        "    ${fwd.proto} dport ${sport} dnat to ${fwd.destination}"
      ) cfg.forwardPorts;
    in
    pkgs.writeText "nat.nft" ''
      table ip nat {
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;
          ${forwardRules}
        }

        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          ${optionalString (
            cfg.externalInterface != null
          ) "oifname \"${cfg.externalInterface}\" masquerade"}
        }
      }
      ${optionalString cfg.enableIPv6 ''
        table ip6 nat {
          chain postrouting {
            type nat hook postrouting priority srcnat; policy accept;
            ${optionalString (
              cfg.externalInterface != null
            ) "oifname \"${cfg.externalInterface}\" masquerade"}
          }
        }
      ''}
    '';

in

{
  options = {
    networking.nat = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable Network Address Translation (NAT/masquerading).

          Allows internal network hosts to access the internet through
          this machine.
        '';
      };

      enableIPv6 = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable IPv6 NAT.";
      };

      externalInterface = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "eth0";
        description = "The external (WAN) network interface.";
      };

      externalIP = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "External IPv4 address for SNAT (instead of masquerade).";
      };

      externalIPv6 = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "External IPv6 address for SNAT.";
      };

      internalInterfaces = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "eth1" ];
        description = "Internal (LAN) interfaces to NAT.";
      };

      internalIPs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "192.168.1.0/24" ];
        description = "Internal IP ranges to NAT (CIDR notation).";
      };

      internalIPv6s = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Internal IPv6 ranges to NAT (CIDR notation).";
      };

      forwardPorts = mkOption {
        type = types.listOf (types.submodule forwardPortOpts);
        default = [ ];
        description = "Port forwarding rules (DNAT).";
      };

      dmzHost = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "192.168.1.10";
        description = "DMZ host — all incoming traffic is forwarded to this IP.";
      };

      extraCommands = mkOption {
        type = types.lines;
        default = "";
        description = "Extra nftables/iptables commands to run after NAT setup.";
      };

      extraStopCommands = mkOption {
        type = types.lines;
        default = "";
        description = "Extra commands to run when NAT is torn down.";
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable IP forwarding
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = true;
    }
    // optionalAttrs cfg.enableIPv6 { "net.ipv6.conf.all.forwarding" = true; };

    # Load NAT rules
    environment.etc."nftables/nat.nft".source = natRules;

    system.activationScripts.nat = stringAfter [ "etc" "firewall" ] ''
      echo "Loading NAT rules..."
      ${pkgs.nftables}/bin/nft -f /etc/nftables/nat.nft || true
      ${cfg.extraCommands}
    '';
  };
}
