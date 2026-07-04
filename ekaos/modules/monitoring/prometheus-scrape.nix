# Prometheus scrape configuration module
# Auto-generates Prometheus scrape target configs from:
# 1. Service observability.metrics contracts (preferred)
# 2. Port contracts with healthCheck paths (fallback)
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

  # Collect observability contracts from enabled services
  enabledServices = filterAttrs (_: s: (s.enable or false) == true) config.services;

  # Build a lookup: serviceName -> observability config (if any)
  observabilityByService = mapAttrs (
    _: svcCfg: svcCfg.observability or { }
  ) enabledServices;

  # Group health check contracts by service name for scrape job generation
  byService = groupBy (c: c.serviceName) healthCheckContracts;

  # Generate a scrape config for a service
  mkScrapeJob =
    serviceName: contracts:
    let
      obs = observabilityByService.${serviceName} or { };
      obsMetrics = obs.metrics or { };

      # Prefer observability.metrics.path, fall back to healthCheck.path
      metricsPath =
        if (obsMetrics.path or null) != null then
          obsMetrics.path
        else
          (head contracts).healthCheck.path;

      # Prefer observability.metrics.port for target, fall back to service port
      metricsPort = obsMetrics.port or null;
      targets =
        if metricsPort != null then
          [ "127.0.0.1:${toString metricsPort}" ]
        else
          map (c: "127.0.0.1:${toString c.port}") contracts;

      # Prefer observability.metrics.interval, fall back to healthCheck.interval
      scrapeInterval =
        if (obsMetrics.interval or null) != null then
          "${toString obsMetrics.interval}s"
        else
          "${toString (head contracts).healthCheck.interval}s";
    in
    {
      job_name = serviceName;
      metrics_path = metricsPath;
      scrape_interval = scrapeInterval;
      static_configs = [
        { inherit targets; }
      ];
    };

  # Also generate jobs for services with observability.metrics but no healthCheck
  servicesWithMetricsOnly = filterAttrs (
    name: svcCfg:
    let
      obs = svcCfg.observability or { };
      obsMetrics = obs.metrics or { };
      hasMetricsPath = (obsMetrics.path or null) != null;
      hasHealthCheck = hasAttr name byService;
    in
    hasMetricsPath && !hasHealthCheck
  ) enabledServices;

  mkMetricsOnlyJob =
    serviceName: svcCfg:
    let
      obsMetrics = svcCfg.observability.metrics;
      port = if obsMetrics.port or null != null then
        obsMetrics.port
      else
        # Use first declared port from the service
        let ports = svcCfg.ports or { }; in
        if ports != { } then
          (head (attrValues ports)).port
        else
          9090; # fallback
    in
    {
      job_name = serviceName;
      metrics_path = obsMetrics.path;
      scrape_interval = "${toString (obsMetrics.interval or 15)}s";
      static_configs = [
        { targets = [ "127.0.0.1:${toString port}" ]; }
      ];
    };

  # All scrape jobs from port contracts (with observability override)
  healthBasedJobs = mapAttrsToList mkScrapeJob byService;
  metricsOnlyJobs = mapAttrsToList mkMetricsOnlyJob servicesWithMetricsOnly;
  autoScrapeJobs = healthBasedJobs ++ metricsOnlyJobs;

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
        from service observability.metrics contracts and port contracts
        with healthCheck paths.
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
