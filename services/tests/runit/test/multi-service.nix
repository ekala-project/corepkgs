# Multi-service interaction test
#
# Runs two services and tests their interaction via localhost

{ pkgs, ... }:

{
  name = "multi-service-interaction";

  modules = [
    {
      # Backend HTTP server
      services.backend = {
        enable = true;
        command = "${pkgs.python3}/bin/python3";
        args = [
          "-c"
          ''
            from http.server import HTTPServer, BaseHTTPRequestHandler

            class Handler(BaseHTTPRequestHandler):
                def do_GET(self):
                    self.send_response(200)
                    self.send_header('Content-type', 'text/plain')
                    self.end_headers()
                    self.wfile.write(b'backend response')

                def log_message(self, format, *args):
                    pass  # Suppress logs

            server = HTTPServer(('127.0.0.1', 8081), Handler)
            server.serve_forever()
          ''
        ];
        description = "Backend HTTP service";
      };

      # Frontend proxy
      services.frontend = {
        enable = true;
        command = "${pkgs.python3}/bin/python3";
        args = [
          "-c"
          ''
            from http.server import HTTPServer, BaseHTTPRequestHandler
            import urllib.request

            class ProxyHandler(BaseHTTPRequestHandler):
                def do_GET(self):
                    # Forward request to backend
                    try:
                        with urllib.request.urlopen('http://127.0.0.1:8081') as response:
                            data = response.read()
                            self.send_response(200)
                            self.send_header('Content-type', 'text/plain')
                            self.send_header('X-Proxied', 'true')
                            self.end_headers()
                            self.wfile.write(data)
                    except Exception as e:
                        self.send_error(500, str(e))

                def log_message(self, format, *args):
                    pass

            server = HTTPServer(('127.0.0.1', 8080), ProxyHandler)
            server.serve_forever()
          ''
        ];
        description = "Frontend proxy service";
      };
    }
  ];

  testScript = ''
    with subtest("backend startup"):
        machine.wait_for_open_port(8081)
        response = machine.succeed("curl -s http://127.0.0.1:8081")
        assert response == "backend response", f"Expected 'backend response', got: {response}"
        log("Backend OK")

    with subtest("frontend proxy"):
        machine.wait_for_open_port(8080)
        response = machine.succeed("curl -s http://127.0.0.1:8080")
        assert response == "backend response", f"Expected proxied backend response, got: {response}"

        # Check proxy header
        verbose_output = machine.succeed("curl -s -v http://127.0.0.1:8080 2>&1")
        assert "X-Proxied: true" in verbose_output, "Proxy header missing"
        log("Frontend proxy OK")

    log("Multi-service test passed!")
  '';
}
