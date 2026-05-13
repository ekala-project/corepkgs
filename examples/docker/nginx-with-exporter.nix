# Example: Nginx web server with Prometheus metrics exporter
# This demonstrates the observability sidecar pattern where a metrics exporter
# runs alongside the main application to expose metrics to Prometheus.
{
  pkgs ? import ../../. { },
}:

let
  services = import ../../services { inherit pkgs; };

  # Nginx configuration that exposes stub_status for metrics
  nginxConf = pkgs.writeText "nginx.conf" ''
    daemon off;
    worker_processes 1;
    pid /tmp/nginx.pid;

    error_log /dev/stderr info;

    events {
      worker_connections 1024;
    }

    http {
      access_log /dev/stdout combined;

      # Temporary directories (writable)
      client_body_temp_path /tmp/client_body;
      proxy_temp_path /tmp/proxy;
      fastcgi_temp_path /tmp/fastcgi;
      uwsgi_temp_path /tmp/uwsgi;
      scgi_temp_path /tmp/scgi;

      server {
        listen 8080;

        location / {
          return 200 "Hello from Runit-supervised Nginx!\n";
          add_header Content-Type text/plain;
        }

        location /health {
          return 200 "OK\n";
          add_header Content-Type text/plain;
        }

        # Expose nginx stub_status for prometheus exporter
        location /nginx_status {
          stub_status on;
          access_log off;
        }
      }
    }
  '';

in
services.buildRunitDockerImage
  {
    # Service definitions
    nginx = {
      enable = true;
      description = "Nginx web server";
      command = "${pkgs.nginx}/bin/nginx";
      args = [
        "-c"
        nginxConf
        "-g"
        "daemon off;"
      ];

      # Run as nginx user (will be created automatically)
      user = "nginx";
      group = "nginx";

      # Nginx outputs logs to stdout/stderr (captured by Docker logs)
      # No separate runit logging needed

      environment = {
        NGINX_PORT = "8080";
      };
    };

    nginx-exporter = {
      enable = true;
      description = "Nginx Prometheus exporter";
      command = "${pkgs.prometheus-nginx-exporter}/bin/nginx-prometheus-exporter";
      args = [
        "-nginx.scrape-uri=http://localhost:8080/nginx_status"
        "-web.listen-address=:9113"
      ];

      # Wait for nginx to be ready before starting
      preStart = ''
        echo "Waiting for nginx to be ready..."
        for i in $(seq 1 30); do
          if ${pkgs.curl}/bin/curl -sf http://localhost:8080/health >/dev/null 2>&1; then
            echo "Nginx is ready!"
            break
          fi
          sleep 1
        done
      '';

      # Exporter can run as a less privileged user
      user = "exporter";
      group = "exporter";

      environment = {
        EXPORTER_PORT = "9113";
      };
    };
  }
  {
    # Docker image configuration
    name = "nginx-with-exporter";
    tag = "latest";

    # Additional packages needed (curl for health check in preStart)
    extraContents = [ pkgs.curl ];

    # Expose ports
    exposedPorts = [
      "8080/tcp" # Nginx HTTP
      "9113/tcp" # Prometheus metrics
    ];

    # Additional Docker configuration
    imageConfig = {
      Labels = {
        "description" = "Nginx web server with Prometheus exporter using runit supervision";
        "maintainer" = "core-pkgs";
        "nginx.version" = pkgs.nginx.version;
        "example.pattern" = "observability-sidecar";
      };

      # Set up temp directories for nginx
      extraFakeRootCommands = ''
        mkdir -p tmp/client_body tmp/proxy tmp/fastcgi tmp/uwsgi tmp/scgi
        chmod 1777 tmp tmp/client_body tmp/proxy tmp/fastcgi tmp/uwsgi tmp/scgi
      '';
    };

    # Commands to run before starting runit
    preStartCommands = ''
      echo "Starting nginx with prometheus exporter sidecar..."
      echo "Nginx will be available on :8080"
      echo "Metrics will be available on :9113/metrics"
    '';
  }
