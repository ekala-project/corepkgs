# Simple HTTP server smoke test
#
# Starts Python's http.server and verifies it responds to requests

{ pkgs, ... }:

{
  name = "http-server";

  modules = [
    {
      services.http-server = {
        enable = true;
        command = "${pkgs.python3}/bin/python3";
        args = [
          "-m"
          "http.server"
          "8080"
          "--bind"
          "127.0.0.1"
        ];
        description = "Simple HTTP server for testing";
      };
    }
  ];

  testScript = ''
    machine.wait_for_open_port(8080)
    log("Testing HTTP server...")
    response = machine.succeed("curl -s http://127.0.0.1:8080")
    assert "Directory listing" in response, f"Expected directory listing, got: {response}"
    log("HTTP server is working!")
  '';
}
