# Prometheus scrape configuration module
# Auto-generates Prometheus scrape target configs from port contracts
# with healthCheck paths defined
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.monitoring.prometheus;
  healthCheckContracts = config.networking.ports.healthChecks or [ ];

  # Group health check contracts by service name for scrape job generation
  byService = groupBy (c: c.serviceName) healthCheckContracts;

  # Generate a scrape config for a service
  mkScrapeJob =
    serviceName: contracts:
    let
      targets = map (c: "127.0.0.1:${toString c.port}") contracts;
      # Use the first contract's health check path as the metrics path
      metricsPath = (head contracts).healthCheck.path;
      scrapeInterval = "${toString (head contracts).healthCheck.interval}s";
    in
    {
      job_name = serviceName;
      metrics_path = metricsPath;
      scrape_interval = scrapeInterval;
      static_configs = [
        { inherit targets; }
      ];
    };

  # All scrape jobs from port contracts
  autoScrapeJobs = mapAttrsToList mkScrapeJob byService;

  # Merge auto-discovered jobs with manually declared ones
  allScrapeJobs = autoScrapeJobs ++ cfg.extraScrapeConfigs;

  # Generate prometheus.yml content
  prometheusConfig = {
    global = {
      scrape_interval = "${toString cfg.globalScrapeInterval}s";
      evaluation_interval = "${toString cfg.evaluationInterval}s";
    };
    scrape_configs = allScrapeJobs;
  };

  configFile = pkgs.writeText "prometheus-scrape-targets.yml" (builtins.toJSON prometheusConfig);

in

{
  options.monitoring.prometheus = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable Prometheus scrape configuration generation.
        Generates a prometheus.yml with scrape targets auto-discovered
        from port contracts that declare healthCheck paths.
      '';
    };

    configPath = mkOption {
      type = types.str;
      default = "/etc/prometheus/prometheus.yml";
      description = "Path where the Prometheus config file is written.";
    };

    globalScrapeInterval = mkOption {
      type = types.ints.positive;
      default = 15;
      description = "Default scrape interval in seconds.";
    };

    evaluationInterval = mkOption {
      type = types.ints.positive;
      default = 15;
      description = "Rule evaluation interval in seconds.";
    };

    extraScrapeConfigs = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      example = literalExpression ''
        [
          {
            job_name = "node";
            static_configs = [ { targets = [ "localhost:9100" ]; } ];
          }
        ]
      '';
      description = ''
        Additional scrape configurations to include.
        Merged with auto-discovered targets from port contracts.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.etc."prometheus/prometheus.yml".source = configFile;

    system.activationScripts.prometheus-config = stringAfter [ "etc" ] ''
      mkdir -p /etc/prometheus
    '';
  };
}
