# Prometheus node exporter service module
# The full Prometheus server is likely better suited for ekapkgs,
# but the node exporter is fundamental system monitoring.
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfgExporter = config.services.prometheus-node-exporter;

in

{
  options = {
    services.prometheus-node-exporter = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the Prometheus node exporter.

          Exposes system metrics (CPU, memory, disk, network) for
          Prometheus scraping.
        '';
      };

      description = mkOption {
        type = types.str;
        default = "Prometheus Node Exporter";
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
        default = "node-exporter";
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

      package = mkOption {
        type = types.package;
        default =
          pkgs.prometheus-node-exporter
            or (throw "prometheus-node-exporter package not available in core-pkgs");
        defaultText = literalExpression "pkgs.prometheus-node-exporter";
        description = "The node exporter package to use.";
      };

      port = mkOption {
        type = types.port;
        default = 9100;
        description = "Port for the node exporter to listen on.";
      };

      listenAddress = mkOption {
        type = types.str;
        default = "0.0.0.0";
        example = "127.0.0.1";
        description = "Address for the node exporter to listen on.";
      };

      enabledCollectors = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "systemd"
          "processes"
        ];
        description = ''
          Additional collectors to enable beyond the defaults.
        '';
      };

      disabledCollectors = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "wifi"
          "mdadm"
        ];
        description = ''
          Default collectors to disable.
        '';
      };

      extraFlags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Extra command-line flags for the node exporter.";
      };
    };
  };

  config = mkIf cfgExporter.enable {
    services.prometheus-node-exporter = {
      command = "${cfgExporter.package}/bin/node_exporter";
      args = [
        "--web.listen-address=${cfgExporter.listenAddress}:${toString cfgExporter.port}"
      ]
      ++ map (c: "--collector.${c}") cfgExporter.enabledCollectors
      ++ map (c: "--no-collector.${c}") cfgExporter.disabledCollectors
      ++ cfgExporter.extraFlags;
      restartPolicy = "always";
      systemd = {
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
      };
    };

    users.users.node-exporter = {
      uid = 9100;
      group = "node-exporter";
      description = "Prometheus Node Exporter";
      isSystemUser = true;
    };

    users.groups.node-exporter = {
      gid = 9100;
    };

    # Register as a Prometheus scrape target
    monitoring.prometheus.extraScrapeConfigs = mkIf config.monitoring.prometheus.enable [
      {
        job_name = "node";
        static_configs = [
          {
            targets = [ "${cfgExporter.listenAddress}:${toString cfgExporter.port}" ];
          }
        ];
      }
    ];
  };
}
