# Adios port of ekaos/modules/services/monitoring/prometheus.nix.
# TODO(adios-cutover): command/args were internal options set by the legacy
# config; they are computed in impl, not user options.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable the Prometheus node exporter.

        Exposes system metrics (CPU, memory, disk, network) for
        Prometheus scraping.
      '';
    };

    description = {
      type = types.string;
      default = "Prometheus Node Exporter";
      description = "Service description.";
    };

    user = {
      type = types.string;
      default = "node-exporter";
      description = "User to run service as.";
    };

    restartPolicy = {
      type = types.string;
      default = "always";
      description = "Restart policy.";
    };

    systemd = {
      type = types.attrsOf types.any;
      default = { };
      description = "Systemd-specific options.";
    };

    package = {
      type = types.nullOr types.derivation;
      default = pkgs.prometheus-node-exporter or null;
      description = "The node exporter package to use.";
    };

    port = {
      type = types.int;
      default = 9100;
      description = "Port for the node exporter to listen on.";
    };

    listenAddress = {
      type = types.string;
      default = "0.0.0.0";
      description = "Address for the node exporter to listen on.";
    };

    enabledCollectors = {
      type = types.listOf types.string;
      default = [ ];
      description = ''
        Additional collectors to enable beyond the defaults.
      '';
    };

    disabledCollectors = {
      type = types.listOf types.string;
      default = [ ];
      description = ''
        Default collectors to disable.
      '';
    };

    extraFlags = {
      type = types.listOf types.string;
      default = [ ];
      description = "Extra command-line flags for the node exporter.";
    };
  };

  inputs = {
    # TODO(adios-cutover): verify tree path once the monitoring batch lands
    # (legacy reads config.monitoring.prometheus.enable, defined in
    # monitoring/prometheus-scrape.nix).
    monitoring.from = { root }: root.monitoring."prometheus-scrape";
  };

  assertions = [
    {
      verify = { options }: options.port >= 0 && options.port <= 65535;
      explain = { options }: "node exporter port must be 0-65535, got ${toString options.port}";
    }
    {
      verify = { options, ... }: (!options.enable) || (options.package != null);
      explain =
        { options, ... }:
        "package option must be set when enabled (prometheus-node-exporter is not in core-pkgs)";
    }
  ];

  impl =
    { options, inputs }:
    if !options.enable then
      { }
    else
      {
        services.prometheus-node-exporter = {
          inherit (options)
            enable
            description
            user
            restartPolicy
            ;
          command = "${options.package}/bin/node_exporter";
          args = [
            "--web.listen-address=${options.listenAddress}:${toString options.port}"
          ]
          ++ builtins.map (c: "--collector.${c}") options.enabledCollectors
          ++ builtins.map (c: "--no-collector.${c}") options.disabledCollectors
          ++ options.extraFlags;
          systemd = {
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
          }
          // options.systemd;
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

        # Register as a Prometheus scrape target when the server is enabled.
        monitoring.prometheus.extraScrapeConfigs =
          if (inputs.monitoring.prometheus.enable or false) then
            [
              {
                job_name = "node";
                static_configs = [
                  {
                    targets = [ "${options.listenAddress}:${toString options.port}" ];
                  }
                ];
              }
            ]
          else
            [ ];
      };
}
