# Node/VM configuration for ekaosTest
# Handles building test VMs from ekaos configurations

{
  config,
  options,
  lib,
  pkgs,
  ...
}:

with lib;

let
  # Base modules that all test nodes should include
  testBaseModules = (import ../../modules/module-list.nix) ++ [
    {
      # Test-specific configuration
      virtualisation.enable = true;
    }
  ];

  # Build a single node configuration
  # When peerHosts is provided, injects /etc/hosts entries for peer VMs
  buildNode =
    name: config:
    {
      peerHosts ? "",
    }:
    let
      # Import ekaos eval-config to build the system
      eval =
        (import ../../eval-config.nix {
          inherit lib pkgs;
        })
          {
            modules =
              testBaseModules
              ++ [
                config
              ]
              ++ lib.optional (peerHosts != "") {
                networking.extraHosts = peerHosts;
              };
          };
    in
    {
      inherit name;
      config = eval.config;
      system = eval.config.system.build.toplevel;
      vm = eval.config.system.build.vm;
    };

in

{
  options = {
    nodes = mkOption {
      type = types.attrsOf types.unspecified;
      default = { };
      description = ''
        Attribute set of test nodes/VMs.

        Each attribute defines a VM with an ekaos configuration.
        For single-VM tests, typically use `nodes.machine`.

        Example:
          nodes.machine = { config, pkgs, ... }: {
            boot.kernelPackages = pkgs.linuxPackages;
            boot.loader.systemd-boot.enable = true;
          };
      '';
      example = literalExpression ''
        {
          machine = { config, pkgs, ... }: {
            boot.kernelPackages = pkgs.linuxPackages;
          };
        }
      '';
    };

    defaults = mkOption {
      type = types.unspecified;
      default = { };
      description = ''
        Configuration applied to all nodes.

        Example:
          defaults = { config, pkgs, ... }: {
            boot.kernelPackages = pkgs.linuxPackages;
          };
      '';
    };

    # Built nodes (internal)
    builtNodes = mkOption {
      type = types.attrsOf types.unspecified;
      internal = true;
      description = "Built node configurations";
    };
  };

  config = {
    # Build all nodes with defaults applied
    # Each node gets /etc/hosts entries for all peer nodes
    builtNodes =
      let
        nodeNames = attrNames config.nodes;
        # Generate /etc/hosts entries mapping each node name to a test IP
        # Uses 192.168.1.{index+1} for each VM in the test network
        nodeIPs = lib.imap1 (i: name: {
          inherit name;
          ip = "192.168.1.${toString i}";
        }) nodeNames;
        # Build hosts file entries for all nodes
        allHostEntries = concatMapStringsSep "\n" (n: "${n.ip} ${n.name}") nodeIPs;
      in
      mapAttrs (
        name: nodeConfig:
        buildNode name (
          if isFunction config.defaults then
            {
              imports = [
                nodeConfig
                config.defaults
              ];
            }
          else
            nodeConfig
        ) { peerHosts = allHostEntries; }
      ) config.nodes;
  };
}
