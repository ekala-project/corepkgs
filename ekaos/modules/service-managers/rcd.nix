# Adios port of ekaos/modules/service-managers/rcd.nix.
#
# Tree path: service-managers/rcd is parent.rcd.
# STUB: BSD rc.d requires BSD kernel and userland.
# Legacy assertions (inside `mkIf cfg.enable`) become adios assertions
# guarded by `!options.enable || ...`. Mutual exclusion reads the sibling
# managers via inputs (parent.*).
{ types, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Enable BSD rc.d as the service manager (stub implementation for ekaos)";
    };
  };

  inputs = {
    systemdMgr.from = { parent }: parent.systemd;
    runitMgr.from = { parent }: parent.runit;
    launchdMgr.from = { parent }: parent.launchd;
  };

  assertions = [
    {
      verify = { options, inputs }: !options.enable || !(inputs.systemdMgr.enable or false);
      explain =
        { options, inputs }:
        "Cannot enable both rcd and systemd service managers. Only one service manager can be enabled at a time.";
    }
    {
      verify = { options, inputs }: !options.enable || !(inputs.runitMgr.enable or false);
      explain =
        { options, inputs }:
        "Cannot enable both rcd and runit service managers. Only one service manager can be enabled at a time.";
    }
    {
      verify = { options, inputs }: !options.enable || !(inputs.launchdMgr.enable or false);
      explain =
        { options, inputs }:
        "Cannot enable both rcd and launchd service managers. Only one service manager can be enabled at a time.";
    }
    {
      verify = { options, inputs }: !options.enable;
      explain = { options, inputs }: ''
        BSD rc.d service manager is not fully implemented for ekaos.
        BSD rc.d is BSD-specific and requires BSD kernel and userland.
        For Linux systems, use systemd or runit instead.

        This stub exists for architecture completeness and may be used
        with extendModules to generate rc.d scripts for reference.
      '';
    }
  ];

  impl =
    { options, inputs }:
    if !options.enable then
      { }
    else
      {
        # Stub: Would generate rc.d scripts here if fully implemented
        # For now, this just ensures the module structure exists for variants

        # User services (users.services.*) would generate per-user rc scripts
        # when implemented. BSD rc.d has no native per-user service support,
        # so this would likely require a wrapper mechanism.
      };
}
