# Boot process test - validates boot stages and systemd initialization

{ pkgs, ... }:

{
  name = "boot-process";

  meta = {
    description = "Test ekaos boot process and systemd targets";
    timeout = 300;
  };

  nodes = {
    machine =
      { config, pkgs, ... }:
      {
        boot.loader.systemd-boot.enable = true;

        virtualisation.enable = true;
      };
  };

  testScript = ''
    # Start the machine
    machine.start()

    # Test boot progression through systemd targets
    machine.wait_for_unit("sysinit.target")
    print("✓ sysinit.target reached")

    machine.wait_for_unit("basic.target")
    print("✓ basic.target reached")

    machine.wait_for_unit("multi-user.target")
    print("✓ multi-user.target reached")

    # Verify systemd is running. multi-user.target is reached before
    # startup finishes, so wait for the boot to settle; a degraded system
    # still fails.
    rc, state = machine.execute(
        "systemctl is-system-running --wait", check_return=False, timeout=300
    )
    if rc != 0:
        print(machine.succeed("systemctl list-units --failed --no-pager"))
    assert rc == 0, f"system is {state.strip()}, not running"

    # Check that basic system services are active
    machine.succeed("systemctl is-active systemd-journald.service")

    # Test journal functionality
    machine.succeed("journalctl --no-pager -n 10")

    # Verify kernel command line was processed
    cmdline = machine.succeed("cat /proc/cmdline")
    print(f"Kernel command line: {cmdline}")

    # Test that we can query systemd
    machine.succeed("systemctl list-units --type=service")
    machine.succeed("systemctl list-units --type=target")

    # Test failed unit detection
    failed = machine.succeed("systemctl list-units --failed --no-pager")
    print(f"Failed units: {failed}")

    # Shutdown cleanly
    machine.shutdown()
  '';
}
