# Service with preStart hook test
#
# Demonstrates using preStart to setup service dependencies

{ pkgs, ... }:

{
  name = "http-with-setup";

  modules = [
    {
      services.http-with-setup = {
        enable = true;
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
      };
    }
  ];

  testScript = ''
    machine.wait_for_open_port(8082)
    log("Testing preStart hook...")
    response = machine.succeed("curl -s http://127.0.0.1:8082/index.html")
    assert "Hello from preStart!" in response, f"Expected preStart content, got: {response}"
    log("preStart hook worked!")
  '';
}
