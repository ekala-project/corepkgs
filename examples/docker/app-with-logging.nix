# Example: Python application with log aggregation sidecar
# This demonstrates the log shipping sidecar pattern where a log collector
# tails application logs and ships them to a centralized location.
{
  pkgs ? import ../../. { },
}:

let
  services = import ../../services { inherit pkgs; };

  # Simple Python web application that generates logs
  app = pkgs.writeScriptBin "demo-app" ''
    #!${pkgs.python3}/bin/python3
    import json
    import time
    import sys
    from http.server import HTTPServer, BaseHTTPRequestHandler
    from datetime import datetime

    # Log to file (will be collected by sidecar)
    LOG_FILE = "/var/log/app/application.log"

    def log(level, message, **kwargs):
        """Write structured JSON logs"""
        entry = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": level,
            "message": message,
            **kwargs
        }
        with open(LOG_FILE, "a") as f:
            f.write(json.dumps(entry) + "\n")
        # Also to stdout for Docker logs
        print(json.dumps(entry), flush=True)

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, format, *args):
            pass  # Disable default logging

        def do_GET(self):
            path = self.path
            log("INFO", "Request received", path=path, method="GET")

            if path == "/":
                self.send_response(200)
                self.send_header("Content-Type", "text/plain")
                self.end_headers()
                self.wfile.write(b"Hello from runit-supervised app!\n")
                log("INFO", "Responded to root request")

            elif path == "/health":
                self.send_response(200)
                self.send_header("Content-Type", "text/plain")
                self.end_headers()
                self.wfile.write(b"OK\n")

            elif path == "/error":
                log("ERROR", "Simulated error endpoint", traceback="Error: Something went wrong")
                self.send_response(500)
                self.send_header("Content-Type", "text/plain")
                self.end_headers()
                self.wfile.write(b"Error simulated\n")

            else:
                log("WARN", "Not found", path=path)
                self.send_response(404)
                self.send_header("Content-Type", "text/plain")
                self.end_headers()
                self.wfile.write(b"Not found\n")

    log("INFO", "Application starting", port=8080)
    server = HTTPServer(("0.0.0.0", 8080), Handler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        log("INFO", "Application shutting down")
        server.shutdown()
  '';

  # Simple log shipper that tails logs and could ship them elsewhere
  # In a real scenario, this would be fluent-bit, fluentd, vector, etc.
  logShipper = pkgs.writeScriptBin "log-shipper" ''
    #!${pkgs.bash}/bin/bash
    set -e

    LOG_SOURCE="/var/log/app/application.log"
    SHIP_TO="''${LOG_DESTINATION:-/var/log/shipped/logs}"

    echo "[log-shipper] Starting log shipper"
    echo "[log-shipper] Source: $LOG_SOURCE"
    echo "[log-shipper] Destination: $SHIP_TO"

    # Create destination directory
    mkdir -p "$(dirname "$SHIP_TO")"

    # Wait for log file to exist
    echo "[log-shipper] Waiting for log file..."
    for i in {1..30}; do
      if [ -f "$LOG_SOURCE" ]; then
        echo "[log-shipper] Log file found!"
        break
      fi
      sleep 1
    done

    if [ ! -f "$LOG_SOURCE" ]; then
      echo "[log-shipper] ERROR: Log file not found after 30 seconds"
      exit 1
    fi

    # Tail the log file and process/ship logs
    echo "[log-shipper] Starting to tail and ship logs..."
    ${pkgs.coreutils}/bin/tail -F "$LOG_SOURCE" | while IFS= read -r line; do
      # Parse JSON and add metadata (in real scenario: enrich, filter, ship)
      echo "$line" | ${pkgs.jq}/bin/jq -c '. + {shipper: "log-shipper", shipped_at: (now | strftime("%Y-%m-%dT%H:%M:%SZ"))}' >> "$SHIP_TO" || echo "$line" >> "$SHIP_TO"
    done
  '';

in
services.buildRunitDockerImage
  {
    # Service definitions
    app = {
      enable = true;
      description = "Demo Python web application";
      command = "${app}/bin/demo-app";

      user = "app";
      group = "app";

      # Create log directory before starting
      preStart = ''
        mkdir -p /var/log/app
        chown app:app /var/log/app
      '';

      environment = {
        PYTHONUNBUFFERED = "1"; # Ensure logs are flushed immediately
      };
    };

    log-shipper = {
      enable = true;
      description = "Log aggregation and shipping sidecar";
      command = "${logShipper}/bin/log-shipper";

      user = "logshipper";
      group = "logshipper";

      # Sidecar needs read access to app logs
      preStart = ''
        echo "Log shipper waiting for application to start..."
        # Wait for app to create log directory
        for i in {1..30}; do
          if [ -d /var/log/app ]; then
            echo "App log directory found!"
            break
          fi
          sleep 1
        done
      '';

      environment = {
        LOG_DESTINATION = "/var/log/shipped/application-shipped.log";
      };
    };
  }
  {
    # Docker image configuration
    name = "app-with-log-shipping";
    tag = "latest";

    # Additional packages
    extraContents = [
      pkgs.coreutils
      pkgs.jq # For JSON log processing
    ];

    # Expose application port
    exposedPorts = [ "8080/tcp" ];

    # Additional Docker configuration
    imageConfig = {
      Labels = {
        "description" = "Python app with log shipping sidecar using runit supervision";
        "maintainer" = "core-pkgs";
        "example.pattern" = "log-aggregation-sidecar";
      };

      # Set up directories
      extraFakeRootCommands = ''
        # Create log directories with appropriate permissions
        mkdir -p var/log/app var/log/shipped

        # App user owns their log directory
        chown 1000:1000 var/log/app

        # Log shipper can write to shipped logs
        chown 1001:1001 var/log/shipped

        # Both need to access /var/log
        chmod 755 var/log
      '';
    };

    # Commands to run before starting runit
    preStartCommands = ''
      echo "Starting demo application with log shipping sidecar..."
      echo "Application will be available on :8080"
      echo "Logs will be written to /var/log/app/application.log"
      echo "Shipped logs will be in /var/log/shipped/application-shipped.log"
      echo ""
      echo "Try these endpoints:"
      echo "  GET / - Hello message"
      echo "  GET /health - Health check"
      echo "  GET /error - Trigger error log"
    '';
  }
