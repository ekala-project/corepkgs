# BSD rc.d HTTP Server Example
# Demonstrates rc.d service generation for FreeBSD, OpenBSD, NetBSD, and DragonFly BSD
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
                <head><title>BSD rc.d Service</title></head>
                <body>
                    <h1>Hello from BSD rc.d!</h1>
                    <p>Service Manager: rc.d</p>
                    <p>Time: {datetime.now()}</p>
                    <p>Port: {PORT}</p>
                    <p>Working Dir: {os.getcwd()}</p>
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
  serviceConfig = {
    http-server = {
      enable = true;
      description = "Simple HTTP Server (BSD rc.d)";

      # Common options work across all BSD variants
      command = "${serverScript}/bin/simple-http-server";
      args = [ ];

      environment = {
        PORT = "8000";
        PYTHONUNBUFFERED = "1";
      };

      path = with pkgs; [
        coreutils
        python3
      ];

      preStart = ''
        echo "Starting HTTP server on port 8000..."
        echo "BSD variant: $(uname -s)"
      '';

      # rc.d-specific options
      rcd = {
        # Variant is automatically set per-builder or can be overridden
        # variant = "freebsd"; # default

        # Dependencies (FreeBSD/NetBSD/DragonFly - ignored on OpenBSD)
        rcProvide = [ "http_server" ];
        rcRequire = [ "DAEMON" "NETWORKING" ];
        rcBefore = [ ];
        rcKeywords = [ "shutdown" ];

        # PID file location
        pidfile = "/var/run/http-server.pid";

        # Extra rc.conf entries
        extraRcConf = ''
          # Additional flags (uncomment to use)
          # http_server_flags="-v"
        '';

        # Custom rc.d script additions
        extraRcScript = ''
          # Custom reload command
          sig_reload="HUP"
        '';
      };
    };
  };

in
{
  # FreeBSD/NetBSD/DragonFly BSD (full-featured with rcorder)
  rcdService = services.buildRcdServices serviceConfig;

  # OpenBSD (simplified sequential system)
  rcdServiceOpenBSD = services.buildRcdServicesOpenBSD serviceConfig;

  # Also export for inspection
  inherit serviceConfig serverScript;
}

# ============================================================================
# INSTALLATION INSTRUCTIONS
# ============================================================================
#
# BUILD BOTH VARIANTS:
# --------------------
# nix-build services/examples/http-server-rcd.nix
#
# This creates two outputs:
# - result-rcdService/etc/rc.d/http-server (FreeBSD/NetBSD/DragonFly)
# - result-rcdServiceOpenBSD/etc/rc.d/http-server (OpenBSD)
# - result-rcdService/etc/rc.conf.d/http-server.sample
# - result-rcdServiceOpenBSD/etc/rc.conf.d/http-server.sample
#
#
# FreeBSD / NetBSD / DragonFly BSD:
# ----------------------------------
# 1. Install rc.d script:
#    sudo cp result-rcdService/etc/rc.d/http-server /usr/local/etc/rc.d/
#    sudo chmod +x /usr/local/etc/rc.d/http-server
#
# 2. Configure in /etc/rc.conf:
#    # View sample configuration
#    cat result-rcdService/etc/rc.conf.d/http-server.sample
#
#    # Add to /etc/rc.conf
#    echo 'http_server_enable="YES"' | sudo tee -a /etc/rc.conf
#
# 3. Start service:
#    sudo service http-server start
#
# 4. Check status:
#    sudo service http-server status
#
# 5. Test:
#    curl http://localhost:8000
#    curl http://localhost:8000/health
#
# 6. Control commands:
#    sudo service http-server stop      # Stop
#    sudo service http-server restart   # Restart
#    sudo service http-server reload    # Reload (SIGHUP)
#
# 7. Enable at boot:
#    # Already enabled via http_server_enable="YES" in rc.conf
#
# 8. View logs:
#    # Check /var/log/messages or use:
#    sudo service http-server status
#
#
# OpenBSD:
# --------
# 1. Install rc.d script:
#    sudo cp result-rcdServiceOpenBSD/etc/rc.d/http-server /etc/rc.d/
#    sudo chmod +x /etc/rc.d/http-server
#
# 2. Configure in /etc/rc.conf.local:
#    # View sample configuration
#    cat result-rcdServiceOpenBSD/etc/rc.conf.d/http-server.sample
#
#    # Add to /etc/rc.conf.local
#    echo 'pkg_scripts="${pkg_scripts} http-server"' | sudo tee -a /etc/rc.conf.local
#
#    # Or use rcctl (recommended):
#    sudo rcctl enable http-server
#
# 3. Start service:
#    sudo rcctl start http-server
#    # Or: sudo /etc/rc.d/http-server start
#
# 4. Check status:
#    sudo rcctl check http-server
#    # Or: sudo /etc/rc.d/http-server check
#
# 5. Test:
#    curl http://localhost:8000
#    curl http://localhost:8000/health
#
# 6. Control commands:
#    sudo rcctl stop http-server        # Stop
#    sudo rcctl restart http-server     # Restart
#    sudo rcctl reload http-server      # Reload (SIGHUP)
#
# 7. View logs:
#    # Check /var/log/messages or /var/log/daemon
#
#
# COMPARISON:
# -----------
# Compare the generated rc.d scripts to see differences between BSD variants:
#
# cat result-rcdService/etc/rc.d/http-server           # FreeBSD/NetBSD/DragonFly
# cat result-rcdServiceOpenBSD/etc/rc.d/http-server    # OpenBSD
#
# Key differences:
# - FreeBSD/NetBSD/DragonFly: Uses 'command', has PROVIDE/REQUIRE metadata
# - OpenBSD: Uses 'daemon', no rcorder metadata, simpler structure
#
# NOTES:
# ------
# - rc.d services don't auto-restart on failure (unlike systemd/runit)
# - Dependencies (REQUIRE/PROVIDE) only affect boot order on FreeBSD/NetBSD/DragonFly
# - OpenBSD uses sequential ordering (no rcorder)
# - For production use, consider adding proper logging and PID file handling
