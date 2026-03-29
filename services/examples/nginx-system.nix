# Example: nginx web server as a system daemon
# This demonstrates a typical system service pattern
{
  pkgs ? import ../../. { },
}:

let
  services = import ../. { inherit pkgs; };

  # Sample nginx configuration
  nginxConfig = pkgs.writeText "nginx.conf" ''
    daemon off;  # systemd manages the daemon
    worker_processes auto;
    error_log stderr;
    pid /run/nginx/nginx.pid;

    events {
      worker_connections 1024;
    }

    http {
      access_log /var/log/nginx/access.log combined;
      error_log /var/log/nginx/error.log;

      server {
        listen 8080;  # Non-privileged port for testing
        server_name localhost;

        location / {
          root ${pkgs.writeTextDir "index.html" "<h1>Hello from Nix-managed nginx!</h1>"};
        }

        location /status {
          stub_status on;
          access_log off;
        }
      }
    }
  '';

  serviceConfig = {
    nginx = {
      enable = true;
      description = "Nginx Web Server";

      # Run as nginx user for security
      user = "nginx";
      group = "nginx";

      command = "${pkgs.nginx}/bin/nginx";
      args = [
        "-c"
        "${nginxConfig}"
      ];

      # Restart on failure
      restartPolicy = "on-failure";

      # Create necessary directories before starting
      preStart = ''
        # Create run directory
        mkdir -p /run/nginx
        chown nginx:nginx /run/nginx

        # Create log directory
        mkdir -p /var/log/nginx
        chown nginx:nginx /var/log/nginx

        # Test configuration
        ${pkgs.nginx}/bin/nginx -t -c ${nginxConfig}
      '';

      # systemd-specific options
      systemd = {
        # Automatically uses multi-user.target for system services
        # (no need to specify wantedBy)

        # Start after network is available
        wants = [ "network-online.target" ];
        after = [
          "network.target"
          "network-online.target"
        ];

        # Additional systemd hardening
        serviceConfig = {
          # Security settings
          NoNewPrivileges = true;
          PrivateTmp = true;

          # Process management
          Type = "simple";
          KillMode = "mixed";
          KillSignal = "SIGQUIT";
          TimeoutStopSec = "5s";

          # Restart settings
          RestartSec = "10s";

          # Resource limits
          LimitNOFILE = 65536;

          # Directories that should exist
          RuntimeDirectory = "nginx";
          RuntimeDirectoryMode = "0755";
          LogsDirectory = "nginx";
          LogsDirectoryMode = "0755";
        };
      };
    };
  };
in
{
  # Build system service
  systemdSystemService = services.buildSystemdSystemServices serviceConfig;

  # Also build user service variant for comparison
  systemdUserService = services.buildSystemdUserServices serviceConfig;
}

# Installation instructions:
#
# 1. Build the system service:
#    nix-build services/examples/nginx-system.nix -A systemdSystemService
#
# 2. Create nginx user (if doesn't exist):
#    sudo useradd -r -s /bin/false nginx
#
# 3. Install the service file:
#    sudo cp result/nginx.service /etc/systemd/system/
#
# 4. Reload systemd and start:
#    sudo systemctl daemon-reload
#    sudo systemctl start nginx
#    sudo systemctl status nginx
#
# 5. Test the server:
#    curl http://localhost:8080
#    curl http://localhost:8080/status
#
# 6. Enable at boot (optional):
#    sudo systemctl enable nginx
#
# 7. View logs:
#    sudo journalctl -u nginx -f
#
# 8. Stop and disable:
#    sudo systemctl stop nginx
#    sudo systemctl disable nginx
#
# Comparison with user service:
#
# Build user service:
#   nix-build services/examples/nginx-system.nix -A systemdUserService
#
# Install to user directory:
#   cp result/nginx.service ~/.config/systemd/user/
#   systemctl --user daemon-reload
#   systemctl --user start nginx
#
# Note: User service runs as current user, not nginx user
