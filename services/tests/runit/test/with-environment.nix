# Service environment variables test
#
# Tests that environment variables are properly passed to services

{ pkgs, ... }:

{
  name = "env-test";

  modules = [
    {
      services.env-test = {
        enable = true;
        command = "${pkgs.python3}/bin/python3";
        args = [
          "-c"
          ''
            from http.server import HTTPServer, BaseHTTPRequestHandler
            import os

            class Handler(BaseHTTPRequestHandler):
                def do_GET(self):
                    self.send_response(200)
                    self.send_header('Content-type', 'text/plain')
                    self.end_headers()
                    msg = f"CUSTOM_VAR={os.environ.get('CUSTOM_VAR', 'NOT_SET')}\n"
                    self.wfile.write(msg.encode())

                def log_message(self, format, *args):
                    pass

            server = HTTPServer(('127.0.0.1', 8083), Handler)
            server.serve_forever()
          ''
        ];
        description = "Service with custom environment";

        environment = {
          CUSTOM_VAR = "test-value-123";
          ANOTHER_VAR = "another-value";
        };
      };
    }
  ];

  testScript = ''
    machine.wait_for_open_port(8083)
    log("Testing environment variables...")
    response = machine.succeed("curl -s http://127.0.0.1:8083")
    assert "CUSTOM_VAR=test-value-123" in response, f"Expected environment variable in response, got: {response}"
    log("Environment variables work!")
  '';
}
