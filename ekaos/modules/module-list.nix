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

  # Security modules
  ./security/pam.nix

  # Service modules
  ./services/getty.nix

  # Service management
  ./systemd.nix

  # Virtualisation
  ./virtualisation/qemu-vm.nix
]
