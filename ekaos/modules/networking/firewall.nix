# Adios port of ekaos/modules/networking/firewall.nix.
#
# Tree path: networking/firewall is parent.networking.firewall.
# Consumes networking.ports.firewall.{tcp,udp} via inputs.ports
# (parent.networking."port-contracts") for automatic port opening.
# TODO(adios-cutover): legacy config wrote trustedInterfaces = [ "lo" ]
# (module-merge append); folded into the impl's effective trusted list
# below instead of a self-write. Priority semantics lost.
# TODO(adios-cutover): identityPolicies is types.listOf types.attrs;
# submodule validation lost (expected keys: name, fromIPs, toPorts,
# toUDPPorts).
# TODO(adios-cutover): writes to environment.systemPackages /
# environment.etc / system.activationScripts target the global namespace;
# the tree must merge this impl fragment with other modules' fragments.
{ types, pkgs, ... }:

let
  unique = xs: builtins.foldl' (acc: x: if builtins.elem x acc then acc else acc ++ [ x ]) [ ] xs;
  canonicalizePortList = ports: unique (builtins.sort builtins.lessThan ports);
in

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable the nftables-based firewall.
        When enabled, all incoming connections are blocked by default
        except for ports explicitly allowed via allowedTCPPorts,
        allowedUDPPorts, or port contracts with openFirewall = true.
      '';
    };

    allowedTCPPorts = {
      type = types.listOf types.int;
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

    allowedUDPPorts = {
      type = types.listOf types.int;
      default = [ ];
      example = [ 53 ];
      description = ''
        List of UDP ports on which incoming connections are accepted.
        Ports from port contracts with openFirewall = true are
        automatically included.
      '';
    };

    trustedInterfaces = {
      type = types.listOf types.string;
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

    allowPing = {
      type = types.bool;
      default = true;
      description = ''
        Whether to respond to incoming ICMPv4 echo requests (pings).
        ICMPv6 is always allowed for NDP functionality.
      '';
    };

    logRefusedConnections = {
      type = types.bool;
      default = false;
      description = "Whether to log refused incoming connection attempts.";
    };

    rejectPackets = {
      type = types.bool;
      default = false;
      description = ''
        If set, refused packets are rejected (ICMP unreachable / TCP RST)
        rather than silently dropped.
      '';
    };

    extraInputRules = {
      type = types.string;
      default = "";
      example = "ip saddr 10.0.0.0/8 accept";
      description = "Additional nftables rules appended to the input-allow chain.";
    };

    identityPolicies = {
      type = types.listOf types.attrs;
      default = [ ];
      description = ''
        Identity-based inter-service firewall policies for the WireGuard
        mesh interface. Each policy allows specific source IPs to reach
        specific destination ports. Populated by fleet identity contracts.

        When non-empty, a default-deny policy is applied on the mesh
        interface and only explicitly declared policies are allowed.
      '';
    };

    meshInterface = {
      type = types.string;
      default = "wg0";
      description = ''
        WireGuard mesh interface name for identity-based policy enforcement.
        Only used when identityPolicies is non-empty.
      '';
    };
  };

  inputs = {
    ports.from = { parent }: parent."port-contracts";
  };

  assertions = [
    {
      verify =
        { options, inputs }:
        builtins.all (p: p >= 0 && p <= 65535) (options.allowedTCPPorts ++ options.allowedUDPPorts);
      explain =
        { options, inputs }:
        "allowedTCPPorts/allowedUDPPorts must be valid ports (0-65535), got ${
          toString (options.allowedTCPPorts ++ options.allowedUDPPorts)
        }";
    }
  ];

  impl =
    { options, inputs }:
    let
      # Merge port-contract-derived ports with manually declared ports
      effectiveTCPPorts = canonicalizePortList (
        options.allowedTCPPorts ++ (inputs.ports.firewall.tcp or [ ])
      );
      effectiveUDPPorts = canonicalizePortList (
        options.allowedUDPPorts ++ (inputs.ports.firewall.udp or [ ])
      );

      # Legacy merged [ "lo" ] via config write; folded in here.
      trusted = unique (options.trustedInterfaces ++ [ "lo" ]);
      ifaceSet = builtins.concatStringsSep ", " (builtins.map (x: ''"${x}"'') trusted);

      portsToNftSet = ports: builtins.concatStringsSep ", " (builtins.map toString ports);

      hasIdentityPolicies = options.identityPolicies != [ ];

      # Generate nftables rules for a single identity policy
      mkIdentityRule =
        policy:
        let
          srcSet = builtins.concatStringsSep ", " policy.fromIPs;
          tcpRule =
            if (policy.toPorts or [ ]) != [ ] then
              ''
                iifname "${options.meshInterface}" ip saddr { ${srcSet} } tcp dport { ${portsToNftSet policy.toPorts} } accept comment "${policy.name}"
              ''
            else
              "";
          udpRule =
            if (policy.toUDPPorts or [ ]) != [ ] then
              ''
                iifname "${options.meshInterface}" ip saddr { ${srcSet} } udp dport { ${portsToNftSet policy.toUDPPorts} } accept comment "${policy.name} (udp)"
              ''
            else
              "";
        in
        tcpRule + udpRule;
    in
    if !options.enable then
      { }
    else
      {
        environment.systemPackages = [ pkgs.nftables ];

        # Generate nftables ruleset
        environment.etc."nftables.conf".text = ''
          #!/usr/sbin/nft -f
          # Generated by ekaos firewall module

          flush ruleset

          table inet ekaos-fw {
            chain input {
              type filter hook input priority filter; policy drop;

              ${
                if ifaceSet != "" then
                  ''
                    iifname { ${ifaceSet} } accept comment "trusted interfaces"
                  ''
                else
                  ""
              }

              # Allow established/related connections
              ct state established,related accept
              ct state invalid drop

              ${
                if hasIdentityPolicies then
                  ''
                    # Identity-based policy on mesh interface (before port-based rules)
                    iifname "${options.meshInterface}" jump identity-allow
                    iifname "${options.meshInterface}" drop comment "default deny on mesh"
                  ''
                else
                  ""
              }

              # Allow new connections to permitted ports
              jump input-allow

              ${
                if options.logRefusedConnections then
                  ''
                    tcp flags syn / fin,syn,rst,ack log level info prefix "refused connection: "
                  ''
                else
                  ""
              }

              ${
                if options.rejectPackets then
                  ''
                    meta l4proto tcp reject with tcp reset
                    reject
                  ''
                else
                  ""
              }
            }

            chain input-allow {
              ${
                if effectiveTCPPorts != [ ] then
                  ''
                    tcp dport { ${portsToNftSet effectiveTCPPorts} } accept
                  ''
                else
                  ""
              }
              ${
                if effectiveUDPPorts != [ ] then
                  ''
                    udp dport { ${portsToNftSet effectiveUDPPorts} } accept
                  ''
                else
                  ""
              }

              ${
                if options.allowPing then
                  ''
                    icmp type echo-request accept comment "allow ping"
                  ''
                else
                  ""
              }

              # Accept essential ICMPv6 (NDP, etc.)
              icmpv6 type != { nd-redirect, 139 } accept comment "essential ICMPv6"

              # DHCPv6 client
              ip6 daddr fe80::/64 udp dport 546 accept comment "DHCPv6 client"

              ${options.extraInputRules}
            }

            ${
              if hasIdentityPolicies then
                ''
                  chain identity-allow {
                    ${builtins.concatStringsSep "\n          " (builtins.map mkIdentityRule options.identityPolicies)}
                  }
                ''
              else
                ""
            }
          }
        '';

        # Load nftables rules during activation
        system.activationScripts.firewall = {
          deps = [ "etc" ];
          text = ''
            echo "Loading nftables firewall rules..."
            ${pkgs.nftables}/bin/nft -f /etc/nftables.conf || echo "Warning: failed to load firewall rules"
          '';
        };
      };
}
