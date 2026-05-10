# Minimal boot test configuration
# Optimized for quick boot testing in QEMU

{
  config,
  lib,
  pkgs,
  ...
}:

{
  # System identification
  system.ekaos.version = "24.11";
  system.ekaos.label = "ekaos-boot-test";

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEFIVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # Use default kernel
  boot.kernelPackages = pkgs.linux.packages.linux_default;

  # Kernel parameters for testing
  boot.kernelParams = [
    "console=ttyS0,115200" # Serial console (primary)
    "console=tty1" # VGA console (backup)
    "quiet" # Reduce verbosity
  ];

  # Minimal system packages
  environment.systemPackages = with pkgs; [
    coreutils
    util-linux
    systemd
  ];

  # Test service that prints success message
  systemd.services.boot-success = {
    enable = true;
    description = "Boot Success Marker";
    command = "${pkgs.coreutils}/bin/echo";
    args = [
      "========================================="
      "ekaos BOOT TEST SUCCESS!"
      "System booted and systemd started"
      "========================================="
    ];

    # Run after multi-user target
    systemd = {
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
    };
  };

  # Add a simple test file to /etc
  environment.etc."boot-test-marker".text = ''
    ekaos boot test
    Generated at build time
  '';
}
