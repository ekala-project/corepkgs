# Adios port of ekaos/modules/service-managers/launchd.nix.
#
# Tree path: service-managers/launchd is parent.launchd.
# STUB: launchd is macOS-specific and cannot run as PID 1 on Linux.
# Legacy assertions (inside `mkIf cfg.enable`) become adios assertions
# guarded by `!options.enable || ...`. Mutual exclusion reads the sibling
# managers via inputs (parent.*).
{ types, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Enable launchd as the service manager (stub implementation for ekaos)";
    };
  };

  inputs = {
    systemdMgr.from = { parent }: parent.systemd;
    runitMgr.from = { parent }: parent.runit;
    rcdMgr.from = { parent }: parent.rcd;
  };

  assertions = [
    {
      verify = { options, inputs }: !options.enable || !(inputs.systemdMgr.enable or false);
      explain =
        { options, inputs }:
        "Cannot enable both launchd and systemd service managers. Only one service manager can be enabled at a time.";
    }
    {
      verify = { options, inputs }: !options.enable || !(inputs.runitMgr.enable or false);
      explain =
        { options, inputs }:
        "Cannot enable both launchd and runit service managers. Only one service manager can be enabled at a time.";
    }
    {
      verify = { options, inputs }: !options.enable || !(inputs.rcdMgr.enable or false);
      explain =
        { options, inputs }:
        "Cannot enable both launchd and rcd service managers. Only one service manager can be enabled at a time.";
    }
    {
      verify = { options, inputs }: !options.enable;
      explain = { options, inputs }: ''
        Launchd service manager is not fully implemented for ekaos.
        Launchd is macOS-specific and cannot run as PID 1 on Linux systems.
        For Linux systems, use systemd or runit instead.

        This stub exists for architecture completeness and may be used
        with extendModules to generate launchd plists for reference.
      '';
    }
  ];

  impl =
    { options, inputs }:
    if !options.enable then
      { }
    else
      {
        # Stub: Would generate launchd plist files here if fully implemented
        # For now, this just ensures the module structure exists for variants

        # User services (users.services.*) would generate LaunchAgent plists
        # at /Library/LaunchAgents/ (global user agents) or
        # ~/Library/LaunchAgents/ (per-user agents) when implemented.
      };
}
