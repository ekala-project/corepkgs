# Test: system boots to multi-user.target
#
# Validates the full boot chain:
#   kernel → initrd → stage-2 → activation → systemd → multi-user.target
#
# This is a lightweight test — no disk image is built.  The nix store is
# shared via 9p and the root filesystem is a tmpfs overlay.
#
# Build:
#   nix-build ekaos/tests -A boot-to-multiuser

{
  pkgs ? import ../.. { },
}:

let
  mkBootTest = import ../lib/testing/boot-test.nix {
    inherit (pkgs) lib;
    inherit pkgs;
  };
in
mkBootTest {
  name = "boot-to-multiuser";

  configuration =
    { config, pkgs, ... }:
    {
      boot.initrd.enable = true;
      boot.initrd.availableKernelModules = [
        "virtio_pci"
        "virtio_blk"
        "9p"
        "9pnet"
        "9pnet_virtio"
        "overlay"
      ];
    };

  expectedTargets = [
    "sysinit.target"
    "basic.target"
    "multi-user.target"
  ];

  timeout = 120;
}
