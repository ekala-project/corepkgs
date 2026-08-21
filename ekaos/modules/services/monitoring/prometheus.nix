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
  cfgExporter = config.services.prometheus.exporters.node;

in

{
  options = {
    services.prometheus.exporters.node = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the Prometheus node exporter.

          Exposes system metrics (CPU, memory, disk, network) for
          Prometheus scraping.
        '';
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
      enable = true;
      description = "Prometheus Node Exporter";
      command = "${cfgExporter.package}/bin/node_exporter";
      args = [
        "--web.listen-address=${cfgExporter.listenAddress}:${toString cfgExporter.port}"
      ]
      ++ map (c: "--collector.${c}") cfgExporter.enabledCollectors
      ++ map (c: "--no-collector.${c}") cfgExporter.disabledCollectors
      ++ cfgExporter.extraFlags;
      user = "node-exporter";
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
