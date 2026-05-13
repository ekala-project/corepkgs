# Example: Generic multi-service Docker image template
# This demonstrates how to run multiple arbitrary services supervised by runit.
# Perfect for sidecar patterns, service meshes, or any multi-process container.
{
  pkgs ? import ../../. { },
}:

let
  services = import ../../services { inherit pkgs; };

  # Example service 1: Simple HTTP server
  httpServer = pkgs.writeScriptBin "http-server" ''
    #!${pkgs.python3}/bin/python3
    from http.server import HTTPServer, BaseHTTPRequestHandler

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, format, *args):
            print(f"[http-server] {format % args}")

        def do_GET(self):
            print(f"[http-server] Request: {self.path}")
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"Service 1: HTTP Server\n")

    print("[http-server] Starting on port 8080")
    HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
  '';

  # Example service 2: Background worker
  worker = pkgs.writeScriptBin "worker" ''
    #!${pkgs.bash}/bin/bash
    echo "[worker] Starting background worker"
    while true; do
      echo "[worker] Processing task at $(date)"
      sleep 10
    done
  '';

  # Example service 3: Health check service
  healthCheck = pkgs.writeScriptBin "health-check" ''
    #!${pkgs.bash}/bin/bash
    echo "[health-check] Starting health check monitor"

    while true; do
      sleep 30

      # Check if http-server is responding
      if ${pkgs.curl}/bin/curl -sf http://localhost:8080 >/dev/null 2>&1; then
        echo "[health-check] HTTP server: OK"
      else
        echo "[health-check] HTTP server: FAILED"
      fi

      # Check if worker is running
      if ${pkgs.procps}/bin/pgrep -f "worker" >/dev/null 2>&1; then
        echo "[health-check] Worker: OK"
      else
        echo "[health-check] Worker: FAILED"
      fi
    done
  '';

in
services.buildRunitDockerImage
  {
    # Define your services here
    # Each service runs independently under runit supervision

    http-server = {
      enable = true;
      description = "HTTP server service";
      command = "${httpServer}/bin/http-server";

      user = "http";
      group = "http";

      environment = {
        SERVICE_NAME = "http-server";
        PORT = "8080";
      };
    };

    worker = {
      enable = true;
      description = "Background worker service";
      command = "${worker}/bin/worker";

      user = "worker";
      group = "worker";

      environment = {
        SERVICE_NAME = "worker";
        WORKER_ID = "1";
      };

      # Worker depends on http-server being up
      preStart = ''
        echo "[worker] Waiting for HTTP server..."
        for i in {1..30}; do
          if ${pkgs.curl}/bin/curl -sf http://localhost:8080 >/dev/null 2>&1; then
            echo "[worker] HTTP server is ready!"
            break
          fi
          sleep 1
        done
      '';
    };

    health-check = {
      enable = true;
      description = "Health monitoring service";
      command = "${healthCheck}/bin/health-check";

      user = "monitor";
      group = "monitor";

      environment = {
        SERVICE_NAME = "health-check";
        CHECK_INTERVAL = "30";
      };

      # Start health checks after other services
      preStart = ''
        echo "[health-check] Waiting for services to start..."
        sleep 5
      '';
    };
  }
  {
    # Docker image configuration
    name = "multi-service-example";
    tag = "latest";

    # Additional packages needed by services
    extraContents = [
      pkgs.curl
      pkgs.procps # For pgrep
    ];

    # Expose ports used by services
    exposedPorts = [
      "8080/tcp" # HTTP server
    ];

    # Additional Docker configuration
    imageConfig = {
      Labels = {
        "description" = "Multi-service container with runit supervision";
        "maintainer" = "core-pkgs";
        "example.pattern" = "multi-service-generic";
        "services.count" = "3";
      };

      # Environment variables accessible to all services
      Env = [
        "PATH=/bin:/usr/bin"
        "CONTAINER_ENV=production"
      ];
    };

    # Commands to run before starting runit
    preStartCommands = ''
      echo "=========================================="
      echo "Multi-Service Container Starting"
      echo "=========================================="
      echo ""
      echo "This container runs 3 services under runit:"
      echo "  1. HTTP Server (port 8080)"
      echo "  2. Background Worker"
      echo "  3. Health Check Monitor"
      echo ""
      echo "All services will start independently and"
      echo "be automatically restarted if they crash."
      echo ""
      echo "To check service status:"
      echo "  docker exec <container> sv status /service/*"
      echo "=========================================="
    '';
  }
