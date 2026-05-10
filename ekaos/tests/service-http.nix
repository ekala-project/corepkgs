# HTTP Server test - validates HTTP server service functionality

{ pkgs, ... }:

let
  # Simple HTTP server script with health endpoint
  serverScript = pkgs.writeScript "simple-http-server" ''
    #!${pkgs.python3}/bin/python3
    import http.server
    import socketserver
    import os
    from datetime import datetime

    PORT = int(os.environ.get('PORT', '8080'))

    class RequestHandler(http.server.SimpleHTTPRequestHandler):
        def do_GET(self):
            if self.path == '/':
                self.send_response(200)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                html = f"""<!DOCTYPE html>
    <html>
    <head><title>ekaos Service Test</title></head>
    <body>
        <h1>Hello from ekaos!</h1>
        <p>Service Manager: systemd</p>
        <p>Time: {datetime.now()}</p>
        <p>Port: {PORT}</p>
        <p>Working Dir: {os.getcwd()}</p>
        <p>User: {os.environ.get('USER', 'unknown')}</p>
    </body>
    </html>"""
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
in
{
  name = "service-http";

  meta = {
    description = "Test HTTP server service with network operations";
    timeout = 300;
  };

  nodes = {
    machine =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        boot.kernelPackages = pkgs.linuxPackages;

        virtualisation.enable = true;

        # Add required packages to environment
        environment.systemPackages = with pkgs; [
          python3
          coreutils
        ];

        # Define HTTP server service
        systemd.services.http-server = {
          description = "Simple HTTP Server Test Service";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];

          path = with pkgs; [
            coreutils
            python3
          ];

          environment = {
            PORT = "8080";
            PYTHONUNBUFFERED = "1"; # For immediate log output
          };

          serviceConfig = {
            ExecStart = serverScript;
            Restart = "always";
            RestartSec = 5;

            # Security hardening
            PrivateTmp = true;
            NoNewPrivileges = true;
          };

          preStart = ''
            echo "Starting HTTP server on port 8080..."
            echo "Platform: $(uname -s)"
          '';
        };
      };
  };

  testScript = ''
    # Start the machine
    machine.start()

    # Wait for multi-user target
    machine.wait_for_unit("multi-user.target")

    # Test that HTTP server service started
    machine.wait_for_unit("http-server.service")
    machine.succeed("systemctl is-active http-server.service")

    # Wait for the port to open
    machine.wait_for_open_port(8080)

    # Test root endpoint using Python urllib (since curl might not be available)
    machine.succeed(
        "${pkgs.python3}/bin/python3 -c 'import urllib.request; "
        "response = urllib.request.urlopen(\"http://localhost:8080/\"); "
        "assert response.status == 200; "
        "content = response.read().decode(\"utf-8\"); "
        "assert \"ekaos\" in content' "
    )

    # Test health endpoint
    machine.succeed(
        "${pkgs.python3}/bin/python3 -c 'import urllib.request; "
        "response = urllib.request.urlopen(\"http://localhost:8080/health\"); "
        "assert response.status == 200; "
        "assert response.read() == b\"OK\"' "
    )

    # Test service status
    machine.succeed("systemctl status http-server.service")

    # Test service restart
    machine.succeed("systemctl restart http-server.service")
    machine.wait_for_unit("http-server.service")
    machine.wait_for_open_port(8080)

    # Verify service still responds after restart
    machine.succeed(
        "${pkgs.python3}/bin/python3 -c 'import urllib.request; "
        "response = urllib.request.urlopen(\"http://localhost:8080/health\"); "
        "assert response.status == 200' "
    )

    # Test that we can see server output in journal
    machine.succeed("journalctl -u http-server.service --no-pager | grep 'Server running on port 8080'")

    # Test service stop and start
    machine.succeed("systemctl stop http-server.service")
    machine.wait_until_fails("systemctl is-active http-server.service")

    machine.succeed("systemctl start http-server.service")
    machine.wait_for_unit("http-server.service")
    machine.wait_for_open_port(8080)

    # Verify service responds after manual start
    machine.succeed(
        "${pkgs.python3}/bin/python3 -c 'import urllib.request; "
        "response = urllib.request.urlopen(\"http://localhost:8080/health\"); "
        "assert response.status == 200' "
    )

    # Shutdown
    machine.shutdown()
  '';
}
