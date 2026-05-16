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
  buildNode =
    name: config:
    let
      # Import ekaos eval-config to build the system
      eval =
        (import ../../eval-config.nix {
          inherit lib pkgs;
        })
          {
            modules = testBaseModules ++ [ config ];
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
    builtNodes = mapAttrs (
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
      )
    ) config.nodes;
  };
}
