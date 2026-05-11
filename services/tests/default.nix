# Example runit service tests
#
# These tests demonstrate lightweight service-to-service testing
# within the nix-build sandbox using runit supervision.

{
  pkgs ? import ../../. { },
}:

let
  runitTestsLib = pkgs.callPackage ./runit-tests.nix { };
  inherit (runitTestsLib) mkRunitTest mkServiceTest;

in

rec {
  # Test 1: Simple HTTP server smoke test
  #
  # Starts Python's http.server and verifies it responds to requests
  simple-http =
    mkServiceTest "http-server"
      {
        command = "${pkgs.python3}/bin/python3";
        args = [
          "-m"
          "http.server"
          "8080"
          "--bind"
          "127.0.0.1"
        ];
        description = "Simple HTTP server for testing";
      }
      ''
        # Wait for HTTP server to be ready
        runitTestWaitPort 8080

        echo "Testing HTTP server..."

        # Make a request
        response=$(${pkgs.curl}/bin/curl -s http://127.0.0.1:8080)

        if echo "$response" | ${pkgs.gnugrep}/bin/grep -q "Directory listing"; then
          echo "HTTP server is working!"
        else
          echo "ERROR: HTTP server response unexpected"
          echo "Response: $response"
          exit 1
        fi
      '';

  # Test 2: Multi-service interaction
  #
  # Runs two services and tests their interaction via localhost
  multi-service = mkRunitTest {
    name = "multi-service-interaction";

    services = {
      # Backend HTTP server
      backend = {
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

      # Frontend proxy (using netcat for simplicity in this test)
      frontend = {
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
    };

    testScript = ''
      # Wait for both services
      runitTestWaitPort 8081 localhost 30
      runitTestWaitPort 8080 localhost 30

      echo "Testing backend directly..."
      backend_response=$(${pkgs.curl}/bin/curl -s http://127.0.0.1:8081)
      if [ "$backend_response" != "backend response" ]; then
        echo "ERROR: Backend response unexpected: $backend_response"
        exit 1
      fi
      echo "Backend OK"

      echo "Testing frontend proxy..."
      frontend_response=$(${pkgs.curl}/bin/curl -s http://127.0.0.1:8080)
      if [ "$frontend_response" != "backend response" ]; then
        echo "ERROR: Frontend response unexpected: $frontend_response"
        exit 1
      fi

      # Check proxy header (using -v to see headers in GET request)
      if ${pkgs.curl}/bin/curl -s -v http://127.0.0.1:8080 2>&1 | ${pkgs.gnugrep}/bin/grep -q "X-Proxied: true"; then
        echo "Frontend proxy OK"
      else
        echo "ERROR: Proxy header missing"
        exit 1
      fi

      echo "Multi-service test passed!"
    '';
  };

  # Test 3: Service with preStart hook
  #
  # Demonstrates using preStart to setup service dependencies
  with-prestart =
    mkServiceTest "http-with-setup"
      {
        command = "${pkgs.python3}/bin/python3";
        args = [
          "-m"
          "http.server"
          "8082"
          "--bind"
          "127.0.0.1"
        ];
        workingDirectory = "/tmp/webroot";
        description = "HTTP server with setup";

        # Create content directory before starting
        preStart = ''
          mkdir -p /tmp/webroot
          echo "Hello from preStart!" > /tmp/webroot/index.html
        '';
      }
      ''
        runitTestWaitPort 8082

        echo "Testing preStart hook..."

        response=$(${pkgs.curl}/bin/curl -s http://127.0.0.1:8082/index.html)
        if echo "$response" | ${pkgs.gnugrep}/bin/grep -q "Hello from preStart!"; then
          echo "preStart hook worked!"
        else
          echo "ERROR: preStart hook did not work"
          echo "Response: $response"
          exit 1
        fi
      '';

  # Test 4: Service environment variables
  #
  # Tests that environment variables are properly passed to services
  with-environment =
    mkServiceTest "env-test"
      {
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
      }
      ''
        runitTestWaitPort 8083

        echo "Testing environment variables..."

        response=$(${pkgs.curl}/bin/curl -s http://127.0.0.1:8083)
        if echo "$response" | ${pkgs.gnugrep}/bin/grep -q "CUSTOM_VAR=test-value-123"; then
          echo "Environment variables work!"
        else
          echo "ERROR: Environment variables not set correctly"
          echo "Response: $response"
          exit 1
        fi
      '';

  # Meta test: Run all tests
  all = pkgs.runCommand "all-runit-tests" { } ''
    echo "Running all runit tests..." >&2

    # List of tests
    ${pkgs.coreutils}/bin/cat > $TMPDIR/tests <<EOF
    ${builtins.concatStringsSep "\n" [
      "${simple-http}"
      "${multi-service}"
      "${with-prestart}"
      "${with-environment}"
    ]}
    EOF

    # Verify all passed
    while read test; do
      if [ -f "$test/result" ]; then
        echo "✓ Test passed: $test" >&2
      else
        echo "✗ Test failed: $test" >&2
        exit 1
      fi
    done < $TMPDIR/tests

    echo "All runit tests passed!" >&2
    mkdir -p $out
    echo "success" > $out/result
  '';
}
