# Launchd service manager for ekaos (STUB IMPLEMENTATION)
# Note: Launchd is primarily for macOS. This is a stub for architecture completeness.
# Consumes services.* definitions but provides minimal ekaos integration.
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.serviceManager.launchd;

in

{
  options.serviceManager.launchd = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable launchd as the service manager (stub implementation for ekaos)";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !(config.serviceManager.systemd.enable or false);
        message = "Cannot enable both launchd and systemd service managers. Only one service manager can be enabled at a time.";
      }
      {
        assertion = !(config.serviceManager.runit.enable or false);
        message = "Cannot enable both launchd and runit service managers. Only one service manager can be enabled at a time.";
      }
      {
        assertion = !(config.serviceManager.rcd.enable or false);
        message = "Cannot enable both launchd and rcd service managers. Only one service manager can be enabled at a time.";
      }
      {
        assertion = false;
        message = ''
          Launchd service manager is not fully implemented for ekaos.
          Launchd is macOS-specific and cannot run as PID 1 on Linux systems.
          For Linux systems, use systemd or runit instead.

          This stub exists for architecture completeness and may be used
          with extendModules to generate launchd plists for reference.
        '';
      }
    ];

    # Stub: Would generate launchd plist files here if fully implemented
    # For now, this just ensures the module structure exists for variants
  };
}
