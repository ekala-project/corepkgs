# Network interface configuration
# Handles interface-specific settings like static IPs, DHCP per-interface
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.networking;

  # Interface configuration type
  interfaceOpts = { name, ... }: {
    options = {
      ipv4.addresses = mkOption {
        type = types.listOf (types.submodule {
          options = {
            address = mkOption {
              type = types.str;
              example = "192.168.1.100";
              description = "IPv4 address";
            };
            prefixLength = mkOption {
              type = types.ints.between 0 32;
              example = 24;
              description = "Subnet prefix length (CIDR notation)";
            };
          };
        });
        default = [];
        description = ''
          List of IPv4 addresses to assign to this interface.

          Each address should include a prefix length for the subnet.
        '';
      };

      ipv6.addresses = mkOption {
        type = types.listOf (types.submodule {
          options = {
            address = mkOption {
              type = types.str;
              example = "2001:db8::1";
              description = "IPv6 address";
            };
            prefixLength = mkOption {
              type = types.ints.between 0 128;
              example = 64;
              description = "Subnet prefix length (CIDR notation)";
            };
          };
        });
        default = [];
        description = ''
          List of IPv6 addresses to assign to this interface.

          Each address should include a prefix length for the subnet.
        '';
      };

      useDHCP = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = false;
        description = ''
          Whether to use DHCP on this interface.

          If null, inherits from networking.useDHCP.
          If true, enables DHCP for this interface.
          If false, disables DHCP for this interface.
        '';
      };

      mtu = mkOption {
        type = types.nullOr types.ints.positive;
        default = null;
        example = 9000;
        description = ''
          Maximum Transmission Unit (MTU) size for this interface.

          Commonly used values:
          - 1500: Standard Ethernet
          - 9000: Jumbo frames
        '';
      };
    };
  };

  # Generate systemd-networkd .network file content
  mkNetworkUnit = iface: icfg:
    let
      useDHCP = if icfg.useDHCP != null then icfg.useDHCP else cfg.useDHCP;
      hasStaticAddrs = icfg.ipv4.addresses != [] || icfg.ipv6.addresses != [];
    in ''
      [Match]
      Name=${iface}

      [Network]
      ${optionalString useDHCP "DHCP=yes"}
      ${concatMapStringsSep "\n" (addr: "Address=${addr.address}/${toString addr.prefixLength}") icfg.ipv4.addresses}
      ${concatMapStringsSep "\n" (addr: "Address=${addr.address}/${toString addr.prefixLength}") icfg.ipv6.addresses}
      ${optionalString (cfg.defaultGateway != null && hasStaticAddrs) "Gateway=${cfg.defaultGateway}"}
      ${optionalString (cfg.defaultGateway6 != null && hasStaticAddrs) "Gateway=${cfg.defaultGateway6}"}

      [Link]
      ${optionalString (icfg.mtu != null) "MTUBytes=${toString icfg.mtu}"}
      RequiredForOnline=no
    '';

  # Only generate configs for interfaces that have been explicitly configured
  configuredInterfaces = filterAttrs (name: icfg:
    icfg.ipv4.addresses != [] ||
    icfg.ipv6.addresses != [] ||
    icfg.useDHCP != null ||
    icfg.mtu != null
  ) cfg.interfaces;

in

{
  options = {
    networking.interfaces = mkOption {
      type = types.attrsOf (types.submodule interfaceOpts);
      default = {};
      example = literalExpression ''
        {
          eth0 = {
            ipv4.addresses = [
              { address = "192.168.1.100"; prefixLength = 24; }
            ];
            useDHCP = false;
          };
          eth1 = {
            useDHCP = true;
          };
        }
      '';
      description = ''
        Configuration for network interfaces.

        Each attribute defines settings for a specific interface.
        Interfaces can have static IP addresses, use DHCP, or both.
      '';
    };
  };

  config = mkIf (configuredInterfaces != {}) {
    # Generate systemd-networkd .network files
    environment.etc = listToAttrs (
      mapAttrsToList (iface: icfg:
        nameValuePair "systemd/network/50-${iface}.network" {
          text = mkNetworkUnit iface icfg;
        }
      ) configuredInterfaces
    );

    # Enable systemd-networkd service
    systemd.services.systemd-networkd = {
      enable = true;
      description = "Network Configuration";
      command = "${config.systemd.package}/lib/systemd/systemd-networkd";
      user = "root";
      restartPolicy = "always";
    };

    # Add activation script to enable systemd-networkd
    system.activationScripts.networkd = stringAfter [ "etc" ] ''
      # Enable systemd-networkd
      echo "Enabling systemd-networkd..."
      mkdir -p /etc/systemd/system/multi-user.target.wants
      ln -sf ${config.systemd.package}/lib/systemd/system/systemd-networkd.service \
             /etc/systemd/system/multi-user.target.wants/systemd-networkd.service
    '';
  };
}
