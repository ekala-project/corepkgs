# ekaos system builder
# Main entry point for building ekaos systems
{
  pkgs ? import ../. { },
  lib ? pkgs.lib,
  configuration ? ./examples/minimal-system.nix,
}:

let
  eval =
    (import ./eval-config.nix {
      inherit lib pkgs;
    })
      {
        modules = [ configuration ];
      };

in

{
  # The complete system closure
  inherit (eval) system;

  # Expose configuration for inspection
  inherit (eval) config options;

  # Convenience attributes
  inherit (eval.config.system.build)
    toplevel
    bootStage2
    activationScript
    etc
    ;

  # Boot loader installer (if systemd-boot is enabled)
  installBootLoader = eval.config.system.build.installBootLoader or null;

  # VM build targets (if virtualisation is enabled)
  vm = eval.config.system.build.vm or null;
  diskImage = eval.config.system.build.diskImage or null;

  # Test infrastructure
  tests = {
    boot = import ./tests/boot-test.nix { inherit pkgs; };
  };
}
