# List of base ekaos modules
# These are loaded for every system configuration
[
  # Boot modules
  ./boot/kernel.nix
  ./boot/initrd.nix
  ./boot/stage-2.nix
  ./boot/systemd-boot.nix

  # System modules
  ./system/toplevel.nix
  ./system/activation.nix
  ./system/etc.nix

  # Config modules
  ./config/users-groups.nix
  ./networking.nix
  ./network-interfaces.nix

  # Security modules
  ./security/pam.nix
  ./security/wrappers
  ./security/sudo.nix

  # Service modules
  ./services/getty.nix
  ./services/networking/dhcpcd.nix
  ./services/networking/sshd.nix

  # Service management
  ./services.nix  # Cross-platform service definitions
  ./systemd.nix   # Systemd implementation (consumes services.*)

  # Virtualisation
  ./virtualisation/qemu-vm.nix
]
