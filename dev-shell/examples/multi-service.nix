# Multi-service development shell example
# Demonstrates service dependencies and inter-service communication
{ pkgs ? import ../../. { } }:

pkgs.mkDevShell {
  # Service configuration using ekaos modules
  modules = [
    {
      # Backend API service
      services.backend = {
        enable = true;
        description = "Backend API Server";

        command = "${pkgs.python3}/bin/python3";
        args = [ "-m" "http.server" "8081" "--bind" "127.0.0.1" ];

        workingDirectory = toString ./.;

        environment = {
          PORT = "8081";
          SERVICE_NAME = "backend";
        };

        restartPolicy = "always";

        preStart = ''
          echo "Starting backend API on http://127.0.0.1:8081"
          mkdir -p ./backend-data
          echo '{"status":"ok","service":"backend"}' > ./backend-data/health.json
        '';
      };

      # Frontend service (depends on backend)
      services.frontend = {
        enable = true;
        description = "Frontend HTTP Server";

        command = "${pkgs.python3}/bin/python3";
        args = [ "-m" "http.server" "8080" "--bind" "127.0.0.1" ];

        workingDirectory = toString ./.;

        environment = {
          PORT = "8080";
          BACKEND_URL = "http://127.0.0.1:8081";
          SERVICE_NAME = "frontend";
        };

        restartPolicy = "always";

        # Frontend starts after backend is ready
        after = [ "backend" ];

        preStart = ''
          echo "Starting frontend on http://127.0.0.1:8080"
          echo "Backend URL: $BACKEND_URL"
          mkdir -p ./frontend-data
          cat > ./frontend-data/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Multi-Service Dev Shell</title>
</head>
<body>
    <h1>Multi-Service Example</h1>
    <p>Frontend running on port 8080</p>
    <p>Backend API on port 8081</p>
    <ul>
        <li><a href="http://127.0.0.1:8080">Frontend</a></li>
        <li><a href="http://127.0.0.1:8081">Backend API</a></li>
    </ul>
</body>
</html>
EOF
        '';
      };

      # Worker service (also depends on backend)
      services.worker = {
        enable = true;
        description = "Background Worker";

        command = "${pkgs.bash}/bin/bash";
        args = [
          "-c"
          ''
            echo "Worker started, polling backend..."
            while true; do
              echo "[$(date)] Worker tick - Backend: $BACKEND_URL"
              sleep 5
            done
          ''
        ];

        environment = {
          BACKEND_URL = "http://127.0.0.1:8081";
          SERVICE_NAME = "worker";
        };

        restartPolicy = "always";

        # Worker starts after backend
        after = [ "backend" ];
      };
    }
  ];

  # Development tools
  packages = with pkgs; [
    curl
    jq
  ];

  # Custom shell hook
  shellHook = ''
    echo "================================================"
    echo "Multi-Service Development Shell"
    echo "================================================"
    echo ""
    echo "Services configured:"
    echo "  - backend:  http://127.0.0.1:8081 (API)"
    echo "  - frontend: http://127.0.0.1:8080 (Web)"
    echo "  - worker:   Background task processor"
    echo ""
    echo "Service dependencies:"
    echo "  frontend → backend"
    echo "  worker   → backend"
    echo ""
    echo "Quick start:"
    echo "  1. Start all services: pc-up"
    echo "  2. Test backend:       curl http://127.0.0.1:8081/health.json"
    echo "  3. Test frontend:      curl http://127.0.0.1:8080"
    echo "  4. View logs:          pc-logs"
    echo "  5. Stop services:      Ctrl+C or pc-down"
    echo ""
    echo "================================================"
    echo ""
  '';

  # Process compose configuration
  processCompose = {
    tui = true;
    autoStart = false;
    logDir = "./.dev/logs";
    dataDir = "./.dev/data";
  };
}
