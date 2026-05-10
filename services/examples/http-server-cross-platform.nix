# Cross-Platform HTTP Server Example
# This demonstrates a single service definition that works across:
# - Linux systemd (user and system services)
# - macOS launchd (user agents and system daemons)
{
  pkgs ? import ../../. { },
}:

let
  services = import ../. { inherit pkgs; };

  # Simple HTTP server script
  serverScript = pkgs.writeScriptBin "simple-http-server" ''
    #!${pkgs.python3}/bin/python3
    import http.server
    import socketserver
    import os
    from datetime import datetime

    PORT = int(os.environ.get('PORT', '8000'))

    class RequestHandler(http.server.SimpleHTTPRequestHandler):
        def do_GET(self):
            if self.path == '/':
                self.send_response(200)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                html = f"""
                <!DOCTYPE html>
                <html>
                <head><title>Cross-Platform Service</title></head>
                <body>
                    <h1>Hello from Nix Service!</h1>
                    <p>Service Manager: Check your system</p>
                    <p>Time: {datetime.now()}</p>
                    <p>Port: {PORT}</p>
                    <p>Working Dir: {os.getcwd()}</p>
                    <p>User: {os.environ.get('USER', 'unknown')}</p>
                </body>
                </html>
                """
                self.wfile.write(html.encode())
            elif self.path == '/health':
                self.send_response(200)
                self.send_header('Content-type', 'text/plain')
                self.end_headers()
                self.wfile.write(b'OK')
            else:
                super().do_GET()

    with socketserver.TCPServer(("", PORT), RequestHandler) as httpd:
        print(f"Server running on port {PORT}")
        httpd.serve_forever()
  '';

  # Unified service configuration
  # Works across all platforms with automatic adjustments
  serviceConfig = {
    http-server = {
      enable = true;
      description = "Simple HTTP Server (Cross-Platform)";

      # Common options work everywhere
      command = "${serverScript}/bin/simple-http-server";
      args = [ ];

      environment = {
        PORT = "8000";
        PYTHONUNBUFFERED = "1"; # For immediate log output
      };

      path = with pkgs; [
        coreutils
        python3
      ];

      restartPolicy = "always";

      preStart = ''
        echo "Starting HTTP server on port 8000..."
        echo "Platform: $(uname -s)"
      '';

      # systemd-specific options (only used on Linux)
      systemd = {
        # For system services: auto-uses multi-user.target
        # For user services: auto-uses default.target

        after = [ "network.target" ];

        serviceConfig = {
          # Security hardening (Linux only)
          PrivateTmp = true;
          NoNewPrivileges = true;

          # Restart configuration
          RestartSec = "5s";
        };
      };

      # launchd-specific options (only used on macOS)
      launchd = {
        # Auto-managed by launchd
        runAtLoad = true;
        keepAlive = true;

        # Process management
        processType = "Background";

        # Resource limits
        softResourceLimits = {
          NumberOfFiles = 1024;
        };

        # Scheduling (optional - demonstrate launchd features)
        # startInterval = 3600;  # Restart hourly if needed
      };

      # runit-specific options
      runit = {
        # Optional logging setup
        # logScript = ''
        #   #!/bin/sh
        #   exec svlogd -tt /var/log/http-server
        # '';

        # Optional extra configuration
        extraRunScript = ''
          # Set resource limits for runit
          ulimit -n 1024
        '';
      };

      # BSD rc.d-specific options
      rcd = {
        rcRequire = [
          "DAEMON"
          "NETWORKING"
        ];
        rcKeywords = [ "shutdown" ];
        pidfile = "/var/run/http-server.pid";
      };
    };
  };
in
{
  # Linux: systemd user service (~/.config/systemd/user/)
  systemdUserService = services.buildSystemdUserServices serviceConfig;

  # Linux: systemd system service (/etc/systemd/system/)
  systemdSystemService = services.buildSystemdSystemServices serviceConfig;

  # macOS: launchd user agent (~/Library/LaunchAgents/)
  launchdUserAgent = services.buildLaunchdUserAgents serviceConfig;

  # macOS: launchd daemon (/Library/LaunchDaemons/)
  launchdDaemon = services.buildLaunchdDaemons serviceConfig;

  # Runit service directory (/etc/sv/)
  runitService = services.buildRunitServices serviceConfig;

  # BSD rc.d (FreeBSD/NetBSD/DragonFly for /usr/local/etc/rc.d/)
  rcdService = services.buildRcdServices serviceConfig;

  # BSD rc.d (OpenBSD for /etc/rc.d/)
  rcdServiceOpenBSD = services.buildRcdServicesOpenBSD serviceConfig;
}

# ============================================================================
# INSTALLATION INSTRUCTIONS
# ============================================================================
#
# BUILD ALL VARIANTS:
# -------------------
# nix-build services/examples/http-server-cross-platform.nix
#
# This creates seven outputs:
# - result-systemdUserService/http-server.service
# - result-systemdSystemService/http-server.service
# - result-launchdUserAgent/http-server.plist
# - result-launchdDaemon/http-server.plist
# - result-runitService/http-server/ (service directory with run script)
# - result-rcdService/etc/rc.d/http-server (FreeBSD/NetBSD/DragonFly)
# - result-rcdServiceOpenBSD/etc/rc.d/http-server (OpenBSD)
#
#
# LINUX - User Service:
# ---------------------
# 1. Install:
#    cp result-systemdUserService/http-server.service ~/.config/systemd/user/
#    systemctl --user daemon-reload
#
# 2. Start:
#    systemctl --user start http-server
#    systemctl --user status http-server
#
# 3. Test:
#    curl http://localhost:8000
#    curl http://localhost:8000/health
#
# 4. View logs:
#    journalctl --user -u http-server -f
#
# 5. Enable at login:
#    systemctl --user enable http-server
#
# 6. Stop:
#    systemctl --user stop http-server
#
#
# LINUX - System Service:
# -----------------------
# 1. Install:
#    sudo cp result-systemdSystemService/http-server.service /etc/systemd/system/
#    sudo systemctl daemon-reload
#
# 2. Start:
#    sudo systemctl start http-server
#    sudo systemctl status http-server
#
# 3. Test:
#    curl http://localhost:8000
#
# 4. View logs:
#    sudo journalctl -u http-server -f
#
# 5. Enable at boot:
#    sudo systemctl enable http-server
#
# 6. Stop:
#    sudo systemctl stop http-server
#
#
# macOS - User Agent:
# -------------------
# 1. Install:
#    cp result-launchdUserAgent/http-server.plist ~/Library/LaunchAgents/
#
# 2. Load and start:
#    launchctl load ~/Library/LaunchAgents/http-server.plist
#
# 3. Check status:
#    launchctl list | grep http-server
#    launchctl list http-server
#
# 4. Test:
#    curl http://localhost:8000
#
# 5. View logs:
#    log stream --predicate 'eventMessage contains "HTTP"' --level info
#    # Or check Console.app
#
# 6. Stop and unload:
#    launchctl unload ~/Library/LaunchAgents/http-server.plist
#
#
# macOS - System Daemon:
# ----------------------
# 1. Install:
#    sudo cp result-launchdDaemon/http-server.plist /Library/LaunchDaemons/
#
# 2. Load and start:
#    sudo launchctl load /Library/LaunchDaemons/http-server.plist
#
# 3. Check status:
#    sudo launchctl list | grep http-server
#
# 4. Test:
#    curl http://localhost:8000
#
# 5. Stop and unload:
#    sudo launchctl unload /Library/LaunchDaemons/http-server.plist
#
#
# RUNIT - Service:
# ----------------
# 1. Install:
#    sudo mkdir -p /etc/sv
#    sudo cp -r result-runitService/http-server /etc/sv/
#
# 2. Enable and start:
#    sudo ln -s /etc/sv/http-server /run/service/
#    # Or on some systems: sudo ln -s /etc/sv/http-server /var/service/
#
# 3. Check status:
#    sudo sv status http-server
#
# 4. Test:
#    curl http://localhost:8000
#
# 5. View logs (if svlogd is configured):
#    tail -f /var/log/http-server/current
#
# 6. Control commands:
#    sudo sv up http-server      # Start
#    sudo sv down http-server    # Stop
#    sudo sv restart http-server # Restart
#    sudo sv once http-server    # Start once (don't restart)
#
# 7. Disable:
#    sudo rm /run/service/http-server  # Or /var/service/http-server
#
#
# BSD RC.D - FreeBSD/NetBSD/DragonFly:
# -------------------------------------
# 1. Install:
#    sudo cp result-rcdService/etc/rc.d/http-server /usr/local/etc/rc.d/
#    sudo chmod +x /usr/local/etc/rc.d/http-server
#
# 2. Configure in /etc/rc.conf:
#    echo 'http_server_enable="YES"' | sudo tee -a /etc/rc.conf
#
# 3. Start:
#    sudo service http-server start
#
# 4. Check status:
#    sudo service http-server status
#
# 5. Test:
#    curl http://localhost:8000
#
# 6. Control commands:
#    sudo service http-server stop      # Stop
#    sudo service http-server restart   # Restart
#    sudo service http-server reload    # Reload (SIGHUP)
#
#
# BSD RC.D - OpenBSD:
# -------------------
# 1. Install:
#    sudo cp result-rcdServiceOpenBSD/etc/rc.d/http-server /etc/rc.d/
#    sudo chmod +x /etc/rc.d/http-server
#
# 2. Enable with rcctl:
#    sudo rcctl enable http-server
#
# 3. Start:
#    sudo rcctl start http-server
#
# 4. Check status:
#    sudo rcctl check http-server
#
# 5. Test:
#    curl http://localhost:8000
#
# 6. Control commands:
#    sudo rcctl stop http-server        # Stop
#    sudo rcctl restart http-server     # Restart
#    sudo rcctl reload http-server      # Reload (SIGHUP)
#
#
# COMPARISON:
# -----------
# Compare the generated files to see how the same service definition
# translates to different service managers:
#
# cat result-systemdUserService/http-server.service
# cat result-systemdSystemService/http-server.service
# cat result-launchdUserAgent/http-server.plist
# cat result-launchdDaemon/http-server.plist
# cat result-runitService/http-server/run
# cat result-rcdService/etc/rc.d/http-server
# cat result-rcdServiceOpenBSD/etc/rc.d/http-server
#
# Note the differences:
# - systemd user vs system: WantedBy target (default.target vs multi-user.target)
# - launchd user vs daemon: Same content (location determines context)
# - systemd vs launchd: Different formats (INI vs plist), same behavior
# - runit: Shell script format, simple and portable
# - rc.d FreeBSD vs OpenBSD: Different variable names (command vs daemon), rcorder metadata
# - All formats: Express the same service in their platform-native way
