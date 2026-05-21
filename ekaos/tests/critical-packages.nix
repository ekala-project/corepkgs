# Test critical MVP packages: nano, cronie, and timesyncd
# Validates Phase 1 implementation

{ pkgs, ... }:

{
  name = "critical-packages";

  meta = {
    description = "Test nano, cronie, and systemd-timesyncd";
    timeout = 600;
  };

  nodes = {
    machine =
      { config, pkgs, ... }:
      {
        # Minimal system configuration
        boot.kernelPackages = pkgs.linuxPackages;
        boot.loader.systemd-boot.enable = true;

        # Enable QEMU guest for testing
        virtualisation.enable = true;
        virtualisation.enableNetwork = true;

        # Add nano to system packages
        environment.systemPackages = [ pkgs.nano ];

        # Enable crond service
        services.crond.enable = true;
        services.crond.systemCronJobs = ''
          # Test cron job - write to file every minute
          * * * * * root echo "Cron test at $(date)" >> /tmp/cron-test.log
        '';

        # Enable timesyncd service
        services.timesyncd.enable = true;
        services.timesyncd.settings = {
          servers = [
            "0.pool.ntp.org"
            "1.pool.ntp.org"
          ];
        };
      };
  };

  testScript = ''
    # Start the machine
    machine.start()

    # Wait for systemd to reach multi-user target
    machine.wait_for_unit("multi-user.target")

    # Test 1: nano is installed and works
    print("Testing nano...")
    machine.succeed("which nano")
    machine.succeed("nano --version")

    # Test nano can create and edit a file
    machine.succeed("echo 'test content' | nano -w /tmp/test-nano.txt")
    machine.succeed("test -f /tmp/test-nano.txt")

    # Test 2: crond is running
    print("Testing crond...")
    machine.wait_for_unit("crond.service")
    machine.succeed("systemctl status crond.service")

    # Verify crond binary exists
    machine.succeed("which crond")
    machine.succeed("which crontab")
    machine.succeed("crond -V")

    # Check that crontab file exists
    machine.succeed("test -f /etc/crontab")

    # Check cron directories exist with correct permissions
    machine.succeed("test -d /etc/cron.d")
    machine.succeed("test -d /var/spool/cron")

    # Wait for cron to execute (up to 90 seconds to catch at least one execution)
    print("Waiting for cron job to execute...")
    machine.succeed("timeout 90 sh -c 'while [ ! -f /tmp/cron-test.log ]; do sleep 1; done'")
    machine.succeed("test -f /tmp/cron-test.log")
    machine.succeed("grep -q 'Cron test' /tmp/cron-test.log")
    print("Cron job executed successfully!")

    # Test 3: timesyncd is running
    print("Testing systemd-timesyncd...")
    machine.wait_for_unit("systemd-timesyncd.service")
    machine.succeed("systemctl status systemd-timesyncd.service")

    # Check timesyncd configuration
    machine.succeed("test -f /etc/systemd/timesyncd.conf")
    machine.succeed("grep -q 'pool.ntp.org' /etc/systemd/timesyncd.conf")

    # Check timesync state directory exists
    machine.succeed("test -d /var/lib/systemd/timesync")

    # Verify time synchronization status
    machine.succeed("timedatectl status")
    machine.succeed("timedatectl show-timesync")

    print("All tests passed!")

    # Clean shutdown
    machine.shutdown()
  '';
}
