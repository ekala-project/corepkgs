# Simple boot test - validates basic system boot and shutdown

{ pkgs, ... }:

{
  name = "simple-boot";

  meta = {
    description = "Test basic ekaos system boot";
    timeout = 300;
  };

  nodes = {
    machine =
      { config, pkgs, ... }:
      {
        # Minimal system configuration
        boot.kernelPackages = pkgs.linuxPackages;
        boot.loader.systemd-boot.enable = true; # Enable systemd-boot bootloader

        # Enable QEMU guest for testing
        virtualisation.enable = true;
        virtualisation.enableNetwork = true;
      };
  };

  testScript = ''
    # Start the machine
    machine.start()

    # Wait for systemd to reach multi-user target
    machine.wait_for_unit("multi-user.target")

    # Test basic commands
    machine.succeed("echo 'Hello from ekaosTest'")
    machine.succeed("uname -a")

    # Clean shutdown
    machine.shutdown()
  '';
}
