# Container detection and support
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    boot.isContainer = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether this system is running as a lightweight container
        inside another system (e.g. systemd-nspawn, Docker, LXC).

        When true, some boot and hardware modules are skipped since
        the host manages the kernel and hardware.
      '';
    };

    boot.containers.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable support for running managed containers
        (systemd-nspawn).
      '';
    };
  };

  config = mkMerge [
    # When running as a container, disable hardware-related boot settings
    (mkIf config.boot.isContainer {
      boot.kernelModules = mkForce [ ];
      boot.initrd.enable = mkDefault false;
      boot.loader.systemd-boot.enable = mkDefault false;
    })

    # When enabling container hosting support
    (mkIf config.boot.containers.enable {
      environment.systemPackages = [ config.systemd.package ];
    })
  ];
}
