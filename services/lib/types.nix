# Extended types for service definitions
{ lib }:

let
  inherit (lib) types mkOption;

  # Metrics endpoint options (distinct from health checks)
  metricsOpts = {
    options = {
      path = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/metrics";
        description = ''
          HTTP path for Prometheus-compatible metrics scraping.
          null disables metrics collection for this service.

          This is distinct from healthCheck.path:
          - healthCheck.path = liveness/readiness probe (200/503)
          - metrics.path = Prometheus exposition format
        '';
      };

      port = mkOption {
        type = types.nullOr types.port;
        default = null;
        description = ''
          Port serving metrics. null means use the service's primary port.
          Useful when metrics are served on a separate admin port.
        '';
      };

      interval = mkOption {
        type = types.ints.positive;
        default = 15;
        description = ''
          Scrape interval in seconds.
        '';
      };
    };
  };
in
{
  # A restart policy type
  restartPolicy = types.enum [
    "always"
    "on-failure"
    "on-abnormal"
    "on-abort"
    "on-watchdog"
    "never"
  ];

  # A command that can be either a string path or a derivation
  command = types.either types.path types.str;

  # Environment values (strings, paths, or packages)
  envValue = types.oneOf [
    types.str
    types.path
    types.package
  ];

  # Network protocol type
  protocol = types.enum [
    "tcp"
    "udp"
  ];

  # Application-layer transport type
  transport = types.enum [
    "http"
    "https"
    "http2"
    "grpc"
    "tcp"
    "udp"
  ];

  # Health check options for a port contract
  healthCheckOpts = {
    options = {
      path = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/health";
        description = ''
          HTTP path for health checks. null disables health checking.
        '';
      };
      interval = mkOption {
        type = types.ints.positive;
        default = 30;
        description = ''
          Health check interval in seconds.
        '';
      };
    };
  };

  # Observability contract for a service
  observabilityContract = {
    options = {
      metrics = mkOption {
        type = types.submodule metricsOpts;
        default = { };
        description = ''
          Metrics endpoint configuration. Consumed by the prometheus-scrape
          module and fleet metrics collectors.
        '';
      };
    };
  };

  # TLS options for a port contract
  tlsOpts = {
    options = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether the upstream service speaks TLS natively.
        '';
      };
      forceRedirect = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether the reverse proxy should redirect HTTP to HTTPS.
        '';
      };
      acme = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to request a Let's Encrypt certificate for this hostname.
          Requires hostname to be set.
        '';
      };
    };
  };

  # Port contract: declares a port a service listens on
  portContract = {
    options = {
      port = mkOption {
        type = types.port;
        description = ''
          Port number this service listens on.
        '';
      };

      protocol = mkOption {
        type = types.enum [
          "tcp"
          "udp"
        ];
        default = "tcp";
        description = ''
          Network protocol. Services listening on both TCP and UDP
          should declare separate port entries.
        '';
      };

      transport = mkOption {
        type = types.enum [
          "http"
          "https"
          "http2"
          "grpc"
          "tcp"
          "udp"
        ];
        default = "http";
        description = ''
          Application-layer transport protocol.
          Used by reverse proxy consumers to select the correct proxy mode.
        '';
      };

      hostname = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "app.example.com";
        description = ''
          Hostname this port should be reachable at.
          Used by reverse proxy consumers for virtual host routing.
          null means no hostname-based routing.
        '';
      };

      path = mkOption {
        type = types.str;
        default = "/";
        example = "/api";
        description = ''
          Path prefix for reverse proxy routing.
        '';
      };

      internal = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether this port is internal-only.
          Internal ports are not exposed via reverse proxy or firewall.
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to automatically open this port in the firewall.
        '';
      };

      tls = mkOption {
        type = types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Whether the upstream service speaks TLS natively.
              '';
            };
            forceRedirect = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Whether the reverse proxy should redirect HTTP to HTTPS.
              '';
            };
            acme = mkOption {
              type = types.bool;
              default = false;
              description = ''
                Whether to request a Let's Encrypt certificate for this hostname.
                Requires hostname to be set.
              '';
            };
          };
        };
        default = { };
        description = ''
          TLS configuration for this port.
        '';
      };

      healthCheck = mkOption {
        type = types.submodule {
          options = {
            path = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "/health";
              description = ''
                HTTP path for health checks. null disables health checking.
              '';
            };
            interval = mkOption {
              type = types.ints.positive;
              default = 30;
              description = ''
                Health check interval in seconds.
              '';
            };
          };
        };
        default = { };
        description = ''
          Health check configuration for this port.
        '';
      };
    };
  };
}
