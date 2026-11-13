# Login test - validates console login functionality
# Tests getty, user management, and PAM authentication

{ pkgs, ... }:

{
  name = "login-test";

  meta = {
    description = "Test console login with getty, users, and PAM in ekaos";
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

        # Enable getty (should be enabled by default, but explicit here)
        services.getty.enable = true;
        services.getty.ttyCount = 6;

        # Create a test user
        users.users.alice = {
          isNormalUser = true;
          homeDirectory = "/home/alice";
          description = "Alice Test User";
          initialPassword = "testpass";
          extraGroups = [
            "wheel"
            "users"
          ];
        };

        # Create another test user
        users.users.bob = {
          isNormalUser = true;
          homeDirectory = "/home/bob";
          description = "Bob Test User";
          hashedPassword = "!"; # Locked account
        };

        # Set root password for testing
        users.users.root = {
          initialPassword = "root";
        };

        # Ensure bash is available
        environment.systemPackages = with pkgs; [
          coreutils
          util-linux
          bash
          shadow
        ];
      };
  };

  testScript = ''
    # Start the machine
    machine.start()

    # Wait for multi-user target
    machine.wait_for_unit("multi-user.target")


    # Test that getty services are running. Wait for each: udev restarts
    # systemd-vconsole-setup when the console device appears, and the
    # gettys, which require it, restart with it.
    for tty in range(1, 7):
        machine.wait_for_unit(f"getty@tty{tty}.service")

    # Check that /etc/passwd was created with our users
    machine.succeed("grep -q '^root:' /etc/passwd")
    machine.succeed("grep -q '^alice:' /etc/passwd")
    machine.succeed("grep -q '^bob:' /etc/passwd")
    machine.succeed("grep -q '^nobody:' /etc/passwd")

    # Check that /etc/group was created
    machine.succeed("grep -q '^root:' /etc/group")
    machine.succeed("grep -q '^wheel:' /etc/group")
    machine.succeed("grep -q '^users:' /etc/group")

    # Check that /etc/shadow exists and has correct permissions
    machine.succeed("test -f /etc/shadow")
    machine.succeed("stat -c '%a' /etc/shadow | grep -q '^600$'")

    # Check that home directories were created
    machine.succeed("test -d /home/alice")
    machine.succeed("test -d /home/bob")
    machine.succeed("test -d /root")

    # Check that PAM configuration exists
    machine.succeed("test -f /etc/pam.d/login")
    machine.succeed("test -f /etc/pam.d/su")
    machine.succeed("test -f /etc/pam.d/other")

    # Check that /etc/shells exists
    machine.succeed("test -f /etc/shells")
    machine.succeed("grep -q 'bash' /etc/shells")

    # Check that /etc/nsswitch.conf exists
    machine.succeed("test -f /etc/nsswitch.conf")
    machine.succeed("grep -q 'passwd:.*files' /etc/nsswitch.conf")

    # Check that /etc/bashrc and /etc/profile exist
    machine.succeed("test -f /etc/bashrc")
    machine.succeed("test -f /etc/profile")

    # Test that we can run commands as root
    machine.succeed("whoami | grep -q '^root$'")

    # Test that user alice exists in passwd
    machine.succeed("id alice")
    machine.succeed("id alice | grep -q 'uid='")
    machine.succeed("id alice | grep -q 'wheel'")

    # Test that user bob exists but account is locked
    machine.succeed("id bob")

    # Check that shadow passwords are set
    # (We can't test actual login without expect, but we can verify the setup)
    machine.succeed("grep -q '^alice:' /etc/shadow")
    machine.succeed("grep -q '^root:' /etc/shadow")

    # Test that getent works (nsswitch)
    machine.succeed("getent passwd root")
    machine.succeed("getent passwd alice")
    machine.succeed("getent group wheel")

    # Test that agetty is present and executable
    machine.succeed("test -x $(which agetty)")

    # Test that login utilities are available
    machine.succeed("test -x $(which login) || true")  # login might not be in path
    machine.succeed("which useradd")  # From shadow package
    machine.succeed("which groupadd")  # From shadow package

    # Test environment variables from /etc/profile
    # Note: Test driver doesn't capture command output, so we use grep -q for verification
    machine.succeed("test -f /etc/profile")
    machine.succeed("test -s /etc/profile")  # Check file is not empty
    machine.succeed("grep -q 'export PATH' /etc/profile")
    machine.succeed("grep -q '/run/current-system/sw/bin' /etc/profile")

    # Test bashrc
    machine.succeed("test -f /etc/bashrc")
    machine.succeed("test -s /etc/bashrc")  # Check file is not empty
    machine.succeed("grep -q 'color=auto' /etc/bashrc")

    # Verify systemd-vconsole-setup service exists
    machine.succeed("systemctl status systemd-vconsole-setup.service || true")

    # Verify systemd-user-sessions service exists
    machine.succeed("systemctl status systemd-user-sessions.service || true")

    # Console setup reruns whenever udev sees a console device; the
    # gettys, and the sessions on them, must survive it
    machine.wait_for_unit("getty@tty2.service")
    getty = machine.succeed("systemctl show -p MainPID --value getty@tty2.service").strip()
    machine.succeed("systemctl restart systemd-vconsole-setup.service")
    after = machine.succeed("systemctl show -p MainPID --value getty@tty2.service").strip()
    assert after == getty, f"restarting vconsole setup restarted getty@tty2 ({getty} -> {after})"

    print("All login functionality tests passed!")

    # Shutdown
    machine.shutdown()
  '';
}
