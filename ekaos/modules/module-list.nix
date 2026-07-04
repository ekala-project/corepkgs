# List of base ekaos modules
# These are loaded for every system configuration
[
  # Boot modules
  ./boot/kernel.nix
  ./boot/initrd.nix
  ./boot/stage-2.nix
  ./boot/systemd-boot.nix
  ./boot/modprobe.nix

  # Hardware
  ./hardware/firmware.nix
  ./hardware/facter

  # System modules
  ./system/toplevel.nix
  ./system/activation.nix
  ./system/etc.nix
  ./system/logind.nix

  # Tasks
  ./tasks/filesystems.nix
  ./tasks/swap.nix
  ./tasks/timers.nix
  ./tasks/tmpfiles.nix

  # Config modules
  ./config/users-groups.nix
  ./config/locale.nix
  ./config/shell-environment.nix
  ./config/nix-daemon.nix
  ./networking.nix
  ./network-interfaces.nix
  ./networking/firewall.nix
  ./networking/dns-zones.nix
  ./networking/wireguard.nix

  # Security modules
  ./security/pam.nix
  ./security/wrappers
  ./security/sudo.nix
  ./security/acme.nix

  # Service modules
  ./services/getty.nix
  ./services/crond.nix
  ./services/timesyncd.nix
  ./services/journald.nix
  ./services/networking/dhcpcd.nix
  ./services/networking/sshd.nix
  ./services/databases/postgresql.nix

  # Service management
  ./services.nix # Cross-platform service definitions
  # Service manager implementations (opt-in via enable options)
  ./service-managers/systemd.nix
  ./service-managers/runit.nix
  ./service-managers/launchd.nix
  ./service-managers/rcd.nix

  # Monitoring
  ./monitoring/prometheus-scrape.nix

  # Miscellaneous
  ./misc/assertions.nix # Assertion checking
  ./misc/defaults.nix # System defaults (including default service manager)

  # Virtualisation
  ./virtualisation/qemu-vm.nix
  ./virtualisation/podman.nix
]
