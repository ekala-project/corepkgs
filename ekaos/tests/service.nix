# Service test - validates systemd service functionality

{ pkgs, ... }:

{
  name = "service-test";

  meta = {
    description = "Test systemd service management in ekaos";
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
        virtualisation.enable = true;

        environment.systemPackages = [ pkgs.curl ];

        systemd.services.test-service = {
          description = "ekaos test oneshot service";
          wantedBy = [ "multi-user.target" ];
          script = "echo test-service ran";
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = "yes";
          };
        };

        systemd.services.test-webserver = {
          description = "ekaos test web server";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          script = ''
            mkdir -p /run/test-webserver
            echo "hello from ekaos" > /run/test-webserver/index.html
            exec ${pkgs.python3}/bin/python3 -m http.server 8080 \
              --bind 127.0.0.1 --directory /run/test-webserver
          '';
        };
      };
  };

  testScript = ''
    # Start the machine
    machine.start()

    # Wait for multi-user target
    machine.wait_for_unit("multi-user.target")

    # Test that our custom service started
    machine.wait_for_unit("test-service.service")
    machine.succeed("systemctl is-active test-service.service")

    # Test the web server service
    machine.wait_for_unit("test-webserver.service")

    # Wait for the port to open
    machine.wait_for_open_port(8080)

    # Test that we can connect to the web server
    out = machine.succeed("curl -fsS http://127.0.0.1:8080/")
    assert "hello from ekaos" in out, out

    # Test service restart
    machine.succeed("systemctl restart test-webserver.service")
    machine.wait_for_unit("test-webserver.service")
    machine.wait_for_open_port(8080)

    # Test service status commands
    machine.succeed("systemctl status test-service.service")
    machine.succeed("systemctl show test-service.service")

    # Shutdown
    machine.shutdown()
  '';
}
