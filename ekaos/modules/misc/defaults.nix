# System defaults for ekaos
# Sets sensible defaults that can be overridden by user configuration
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  # Enable systemd as the default service manager for the base system
  # This ensures system.build.toplevel uses systemd by default
  serviceManager.systemd.enable = mkDefault true;

  # Note: The serviceManager.<name>.enable options are internal implementation details.
  # Users should select service managers by choosing the appropriate build attribute:
  #   - config.system.build.systemd  (systemd variant)
  #   - config.system.build.runit    (runit variant)
  #   - config.system.build.launchd  (stub)
  #   - config.system.build.rcd      (stub)
  #
  # The default system.build.toplevel uses systemd (set here via mkDefault).
}
