# Adios port of ekaos/modules/networking/nat.nix.
#
# Tree path: networking/nat is parent.networking.nat.
# Self-contained; no cross-module reads. The nat.nft derivation is built
# in the top-level let (pkgs available there; impl only sees
# { options, inputs }).
# TODO(adios-cutover): forwardPorts is types.listOf types.attrs; legacy
# submodule validation lost (sourcePort was either port or a
# { from, to } range submodule; proto defaults to "tcp"). Element defaults
# are applied via `or` fallbacks in impl.
# TODO(adios-cutover): externalIP, externalIPv6, internalIPs,
# internalIPv6s, internalInterfaces, dmzHost, extraStopCommands are kept
# for shape parity but have no consumer in impl (same as legacy).
{ types, pkgs, ... }:

let
  mkNatRules =
    {
      enableIPv6,
      externalInterface,
      forwardPorts,
    }:
    let
      forwardRules = builtins.concatStringsSep "\n" (
        builtins.map (
          fwd:
          let
            sport =
              if builtins.isInt fwd.sourcePort then
                toString fwd.sourcePort
              else
                "${toString fwd.sourcePort.from}-${toString fwd.sourcePort.to}";
          in
          "    ${fwd.proto or "tcp"} dport ${sport} dnat to ${fwd.destination}"
        ) forwardPorts
      );
    in
    pkgs.writeText "nat.nft" ''
      table ip nat {
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;
          ${forwardRules}
        }

        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          ${if externalInterface != null then "oifname \"${externalInterface}\" masquerade" else ""}
        }
      }
      ${
        if enableIPv6 then
          ''
            table ip6 nat {
              chain postrouting {
                type nat hook postrouting priority srcnat; policy accept;
                ${if externalInterface != null then "oifname \"${externalInterface}\" masquerade" else ""}
              }
            }
          ''
        else
          ""
      }
    '';
in

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable Network Address Translation (NAT/masquerading).

        Allows internal network hosts to access the internet through
        this machine.
      '';
    };

    enableIPv6 = {
      type = types.bool;
      default = false;
      description = "Whether to enable IPv6 NAT.";
    };

    externalInterface = {
      type = types.nullOr types.string;
      default = null;
      example = "eth0";
      description = "The external (WAN) network interface.";
    };

    externalIP = {
      type = types.nullOr types.string;
      default = null;
      description = "External IPv4 address for SNAT (instead of masquerade).";
    };

    externalIPv6 = {
      type = types.nullOr types.string;
      default = null;
      description = "External IPv6 address for SNAT.";
    };

    internalInterfaces = {
      type = types.listOf types.string;
      default = [ ];
      example = [ "eth1" ];
      description = "Internal (LAN) interfaces to NAT.";
    };

    internalIPs = {
      type = types.listOf types.string;
      default = [ ];
      example = [ "192.168.1.0/24" ];
      description = "Internal IP ranges to NAT (CIDR notation).";
    };

    internalIPv6s = {
      type = types.listOf types.string;
      default = [ ];
      description = "Internal IPv6 ranges to NAT (CIDR notation).";
    };

    forwardPorts = {
      type = types.listOf types.attrs;
      default = [ ];
      description = "Port forwarding rules (DNAT).";
    };

    dmzHost = {
      type = types.nullOr types.string;
      default = null;
      example = "192.168.1.10";
      description = "DMZ host — all incoming traffic is forwarded to this IP.";
    };

    extraCommands = {
      type = types.string;
      default = "";
      description = "Extra nftables/iptables commands to run after NAT setup.";
    };

    extraStopCommands = {
      type = types.string;
      default = "";
      description = "Extra commands to run when NAT is torn down.";
    };
  };

  impl =
    { options, inputs }:
    if !options.enable then
      { }
    else
      {
        # Enable IP forwarding
        boot.kernel.sysctl = {
          "net.ipv4.ip_forward" = true;
        }
        // (if options.enableIPv6 then { "net.ipv6.conf.all.forwarding" = true; } else { });

        # Load NAT rules
        environment.etc."nftables/nat.nft".source = mkNatRules {
          inherit (options) enableIPv6 externalInterface forwardPorts;
        };

        system.activationScripts.nat = {
          deps = [
            "etc"
            "firewall"
          ];
          text = ''
            echo "Loading NAT rules..."
            ${pkgs.nftables}/bin/nft -f /etc/nftables/nat.nft || true
            ${options.extraCommands}
          '';
        };
      };
}
