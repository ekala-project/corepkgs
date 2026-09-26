# Adios port of ekaos/modules/monitoring/prometheus-scrape.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable Prometheus scrape configuration generation.
        Generates a prometheus.yml with scrape targets auto-discovered
        from service observability.metrics contracts and port contracts
        with healthCheck paths.
      '';
    };

    configPath = {
      type = types.string;
      default = "/etc/prometheus/prometheus.yml";
      description = "Path where the Prometheus config file is written.";
    };

    globalScrapeInterval = {
      type = types.int;
      default = 15;
      description = "Default scrape interval in seconds.";
    };

    evaluationInterval = {
      type = types.int;
      default = 15;
      description = "Rule evaluation interval in seconds.";
    };

    extraScrapeConfigs = {
      type = types.listOf types.attrs;
      default = [ ];
      example = [
        {
          job_name = "node";
          static_configs = [ { targets = [ "localhost:9100" ]; } ];
        }
      ];
      description = ''
        Additional scrape configurations to include.
        Merged with auto-discovered targets from port contracts.
      '';
    };
  };

  inputs = {
    # TODO(adios-cutover): provides networking.ports.healthChecks (internal
    # option defined in ekaos/modules/networking/port-contracts.nix); flat
    # leaf name pending that port — full legacy path used below.
    portContracts.from = { root }: root.networking.port-contracts;
    # TODO(adios-cutover): LOAD-BEARING. Legacy reads the whole config.services
    # subtree (every enabled service's observability/ports contracts). There is
    # no single module node for this; needs a subtree/wildcard input or an
    # aggregator. Full legacy path used below pending tree semantics.
    services.from = { root }: root.services;
  };

  assertions = [
    {
      # Legacy type was types.ints.positive.
      verify = { options, ... }: options.globalScrapeInterval > 0;
      explain =
        { options, ... }:
        "globalScrapeInterval must be positive, got ${toString options.globalScrapeInterval}";
    }
    {
      # Legacy type was types.ints.positive.
      verify = { options, ... }: options.evaluationInterval > 0;
      explain =
        { options, ... }: "evaluationInterval must be positive, got ${toString options.evaluationInterval}";
    }
  ];

  impl =
    { options, inputs }:
    if !options.enable then
      { }
    else
      let
        # Smallest local reimplementations (no nixpkgs lib allowed).
        filterAttrs =
          pred: set:
          builtins.listToAttrs (
            builtins.map (n: {
              name = n;
              value = set.${n};
            }) (builtins.filter (n: pred n set.${n}) (builtins.attrNames set))
          );
        groupBy =
          keyFn: list:
          builtins.foldl' (
            acc: x:
            let
              k = keyFn x;
            in
            acc // { ${k} = (acc.${k} or [ ]) ++ [ x ]; }
          ) { } list;

        healthCheckContracts = inputs.portContracts.networking.ports.healthChecks or [ ];

        # Collect observability contracts from enabled services.
        enabledServices = filterAttrs (_: s: (s.enable or false) == true) inputs.services.services;

        # Build a lookup: serviceName -> observability config (if any).
        observabilityByService = builtins.mapAttrs (_: svcCfg: svcCfg.observability or { }) enabledServices;

        # Group health check contracts by service name for scrape generation.
        byService = groupBy (c: c.serviceName) healthCheckContracts;

        # Generate a scrape config for a service.
        mkScrapeJob =
          serviceName: contracts:
          let
            obs = observabilityByService.${serviceName} or { };
            obsMetrics = obs.metrics or { };

            # Prefer observability.metrics.path, fall back to healthCheck.path.
            metricsPath =
              if (obsMetrics.path or null) != null then
                obsMetrics.path
              else
                (builtins.elemAt contracts 0).healthCheck.path;

            # Prefer observability.metrics.port for target, else service port.
            metricsPort = obsMetrics.port or null;
            targets =
              if metricsPort != null then
                [ "127.0.0.1:${toString metricsPort}" ]
              else
                builtins.map (c: "127.0.0.1:${toString c.port}") contracts;

            # Prefer observability.metrics.interval, else healthCheck.interval.
            scrapeInterval =
              if (obsMetrics.interval or null) != null then
                "${toString obsMetrics.interval}s"
              else
                "${toString (builtins.elemAt contracts 0).healthCheck.interval}s";
          in
          {
            job_name = serviceName;
            metrics_path = metricsPath;
            scrape_interval = scrapeInterval;
            static_configs = [
              { inherit targets; }
            ];
          };

        # Also generate jobs for services with observability.metrics but no
        # healthCheck.
        servicesWithMetricsOnly = filterAttrs (
          name: svcCfg:
          let
            obs = svcCfg.observability or { };
            obsMetrics = obs.metrics or { };
            hasMetricsPath = (obsMetrics.path or null) != null;
            hasHealthCheck = builtins.hasAttr name byService;
          in
          hasMetricsPath && !hasHealthCheck
        ) enabledServices;

        mkMetricsOnlyJob =
          serviceName: svcCfg:
          let
            obsMetrics = svcCfg.observability.metrics;
            port =
              if obsMetrics.port or null != null then
                obsMetrics.port
              else
                # Use first declared port from the service.
                let
                  ports = svcCfg.ports or { };
                in
                if ports != { } then (builtins.elemAt (builtins.attrValues ports) 0).port else 9090; # fallback
          in
          {
            job_name = serviceName;
            metrics_path = obsMetrics.path;
            scrape_interval = "${toString (obsMetrics.interval or 15)}s";
            static_configs = [
              { targets = [ "127.0.0.1:${toString port}" ]; }
            ];
          };

        # All scrape jobs from port contracts (with observability override).
        healthBasedJobs = builtins.map (n: mkScrapeJob n byService.${n}) (builtins.attrNames byService);
        metricsOnlyJobs = builtins.map (n: mkMetricsOnlyJob n servicesWithMetricsOnly.${n}) (
          builtins.attrNames servicesWithMetricsOnly
        );
        autoScrapeJobs = healthBasedJobs ++ metricsOnlyJobs;

        # Merge auto-discovered jobs with manually declared ones.
        allScrapeJobs = autoScrapeJobs ++ options.extraScrapeConfigs;

        # Generate prometheus.yml content.
        prometheusConfig = {
          global = {
            scrape_interval = "${toString options.globalScrapeInterval}s";
            evaluation_interval = "${toString options.evaluationInterval}s";
          };
          scrape_configs = allScrapeJobs;
        };

        configFile = pkgs.writeText "prometheus-scrape-targets.yml" (builtins.toJSON prometheusConfig);
      in
      {
        environment.etc."prometheus/prometheus.yml".source = configFile;

        # TODO(adios-cutover): stringAfter [ "etc" ] ordering dropped.
        system.activationScripts.prometheus-config = ''
          mkdir -p /etc/prometheus
        '';
      };
}
