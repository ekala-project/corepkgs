# BSD rc.d service manager for ekaos (STUB IMPLEMENTATION)
# Note: BSD rc.d is for BSD systems. This is a stub for architecture completeness.
# Consumes services.* definitions but provides minimal ekaos integration.
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.serviceManager.rcd;

in

{
  options.serviceManager.rcd = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable BSD rc.d as the service manager (stub implementation for ekaos)";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !(config.serviceManager.systemd.enable or false);
        message = "Cannot enable both rcd and systemd service managers. Only one service manager can be enabled at a time.";
      }
      {
        assertion = !(config.serviceManager.runit.enable or false);
        message = "Cannot enable both rcd and runit service managers. Only one service manager can be enabled at a time.";
      }
      {
        assertion = !(config.serviceManager.launchd.enable or false);
        message = "Cannot enable both rcd and launchd service managers. Only one service manager can be enabled at a time.";
      }
      {
        assertion = false;
        message = ''
          BSD rc.d service manager is not fully implemented for ekaos.
          BSD rc.d is BSD-specific and requires BSD kernel and userland.
          For Linux systems, use systemd or runit instead.

          This stub exists for architecture completeness and may be used
          with extendModules to generate rc.d scripts for reference.
        '';
      }
    ];

    # Stub: Would generate rc.d scripts here if fully implemented
    # For now, this just ensures the module structure exists for variants
  };
}
