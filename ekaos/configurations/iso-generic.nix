# Generic EkaOS installation ISO
#
# Build with:
#   nix-build -A isoImage '<ekaos>' -I ekaos=./ekaos/configurations/iso-generic.nix
#
# Or directly:
#   nix-build ekaos/configurations/iso-generic.nix
#
# The resulting ISO is at: result/iso/ekaos-generic-*.iso
{
  system ? "x86_64-linux",
  pkgs ? import ../../. { inherit system; },
}:
let
  ekaos = import ../default.nix {
    inherit system pkgs;
    modules = [
      ../modules/installer/installation-cd-base.nix
      ../modules/installer/hardware-profile.nix
      (
        { lib, ... }:
        {
          isoImage.edition = "generic";
          isoImage.bootMenuLabel = "EkaOS Installer";

          system.ekaos.version = "25.05";
          boot.kernelPackages = pkgs.linux.pkgs;
        }
      )
    ];
  };
in
ekaos.config.system.build.isoImage
