# nftables-based firewall for ekaos
# Consumes networking.ports.firewall.{tcp,udp} from port contracts
# for automatic port opening
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.networking.firewall;

  canonicalizePortList = ports: unique (builtins.sort builtins.lessThan ports);

  # Merge port-contract-derived ports with manually declared ports
  effectiveTCPPorts = canonicalizePortList (
    cfg.allowedTCPPorts ++ (config.networking.ports.firewall.tcp or [ ])
  );
  effectiveUDPPorts = canonicalizePortList (
    cfg.allowedUDPPorts ++ (config.networking.ports.firewall.udp or [ ])
  );

  ifaceSet = concatStringsSep ", " (map (x: ''"${x}"'') cfg.trustedInterfaces);

  portsToNftSet = ports: concatStringsSep ", " (map toString ports);

  hasIdentityPolicies = cfg.identityPolicies != [ ];

  # Generate nftables rules for a single identity policy
  mkIdentityRule =
    policy:
    let
      srcSet = concatStringsSep ", " policy.fromIPs;
      tcpRule = optionalString (policy.toPorts != [ ]) ''
        iifname "${cfg.meshInterface}" ip saddr { ${srcSet} } tcp dport { ${portsToNftSet policy.toPorts} } accept comment "${policy.name}"
      '';
      udpRule = optionalString (policy.toUDPPorts != [ ]) ''
        iifname "${cfg.meshInterface}" ip saddr { ${srcSet} } udp dport { ${portsToNftSet policy.toUDPPorts} } accept comment "${policy.name} (udp)"
      '';
    in
    tcpRule + udpRule;

in

{
  options.networking.firewall = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable the nftables-based firewall.
        When enabled, all incoming connections are blocked by default
        except for ports explicitly allowed via allowedTCPPorts,
        allowedUDPPorts, or port contracts with openFirewall = true.
      '';
    };

    allowedTCPPorts = mkOption {
      type = types.listOf types.port;
      default = [ ];
      example = [
        22
        80
        443
      ];
      description = ''
        List of TCP ports on which incoming connections are accepted.
        Ports from port contracts with openFirewall = true are
        automatically included.
      '';
    };

    allowedUDPPorts = mkOption {
      type = types.listOf types.port;
      default = [ ];
      example = [ 53 ];
      description = ''
        List of UDP ports on which incoming connections are accepted.
        Ports from port contracts with openFirewall = true are
        automatically included.
      '';
    };

    trustedInterfaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "lo"
        "br0"
      ];
      description = ''
        Traffic from these interfaces is accepted unconditionally.
        The loopback interface (lo) is always trusted.
      '';
    };

    allowPing = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to respond to incoming ICMPv4 echo requests (pings).
        ICMPv6 is always allowed for NDP functionality.
      '';
    };

    logRefusedConnections = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to log refused incoming connection attempts.
      '';
    };

    rejectPackets = mkOption {
      type = types.bool;
      default = false;
      description = ''
        If set, refused packets are rejected (ICMP unreachable / TCP RST)
        rather than silently dropped.
      '';
    };

    extraInputRules = mkOption {
      type = types.lines;
      default = "";
      example = "ip saddr 10.0.0.0/8 accept";
      description = ''
        Additional nftables rules appended to the input-allow chain.
      '';
    };

    identityPolicies = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Human-readable policy name for comments.";
            };

            fromIPs = mkOption {
              type = types.listOf types.str;
              description = ''
                Source IP addresses (typically WireGuard mesh IPs) allowed
                to reach the target ports.
              '';
            };

            toPorts = mkOption {
              type = types.listOf types.port;
              description = "Destination TCP ports the source IPs may connect to.";
            };

            toUDPPorts = mkOption {
              type = types.listOf types.port;
              default = [ ];
              description = "Destination UDP ports the source IPs may connect to.";
            };
          };
        }
      );
      default = [ ];
      description = ''
        Identity-based inter-service firewall policies for the WireGuard
        mesh interface. Each policy allows specific source IPs to reach
        specific destination ports. Populated by fleet identity contracts.

        When non-empty, a default-deny policy is applied on the mesh
        interface and only explicitly declared policies are allowed.
      '';
    };

    meshInterface = mkOption {
      type = types.str;
      default = "wg0";
      description = ''
        WireGuard mesh interface name for identity-based policy enforcement.
        Only used when identityPolicies is non-empty.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Always trust loopback
    networking.firewall.trustedInterfaces = [ "lo" ];

    environment.systemPackages = [ pkgs.nftables ];

    # Generate nftables ruleset
    environment.etc."nftables.conf".text = ''
      #!/usr/sbin/nft -f
      # Generated by ekaos firewall module

      flush ruleset

      table inet ekaos-fw {
        chain input {
          type filter hook input priority filter; policy drop;

          ${optionalString (ifaceSet != "") ''
            iifname { ${ifaceSet} } accept comment "trusted interfaces"
          ''}

          # Allow established/related connections
          ct state established,related accept
          ct state invalid drop

          ${optionalString hasIdentityPolicies ''
            # Identity-based policy on mesh interface (before port-based rules)
            iifname "${cfg.meshInterface}" jump identity-allow
            iifname "${cfg.meshInterface}" drop comment "default deny on mesh"
          ''}

          # Allow new connections to permitted ports
          jump input-allow

          ${optionalString cfg.logRefusedConnections ''
            tcp flags syn / fin,syn,rst,ack log level info prefix "refused connection: "
          ''}

          ${optionalString cfg.rejectPackets ''
            meta l4proto tcp reject with tcp reset
            reject
          ''}
        }

        chain input-allow {
          ${optionalString (effectiveTCPPorts != [ ]) ''
            tcp dport { ${portsToNftSet effectiveTCPPorts} } accept
          ''}
          ${optionalString (effectiveUDPPorts != [ ]) ''
            udp dport { ${portsToNftSet effectiveUDPPorts} } accept
          ''}

          ${optionalString cfg.allowPing ''
            icmp type echo-request accept comment "allow ping"
          ''}

          # Accept essential ICMPv6 (NDP, etc.)
          icmpv6 type != { nd-redirect, 139 } accept comment "essential ICMPv6"

          # DHCPv6 client
          ip6 daddr fe80::/64 udp dport 546 accept comment "DHCPv6 client"

          ${cfg.extraInputRules}
        }

        ${optionalString hasIdentityPolicies ''
          chain identity-allow {
            ${concatMapStringsSep "\n          " mkIdentityRule cfg.identityPolicies}
          }
        ''}
      }
    '';

    # Load nftables rules during activation
    system.activationScripts.firewall = stringAfter [ "etc" ] ''
      echo "Loading nftables firewall rules..."
      ${pkgs.nftables}/bin/nft -f /etc/nftables.conf || echo "Warning: failed to load firewall rules"
    '';
  };
}
