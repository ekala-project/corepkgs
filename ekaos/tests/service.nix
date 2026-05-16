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
        boot.kernelPackages = pkgs.linuxPackages;

        virtualisation.enable = true;
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
    machine.succeed("curl -f http://localhost:8080/")

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
