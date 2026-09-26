# Adios port of ekaos/modules/misc/defaults.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
#
# Legacy is a config-only module (no options of its own); it becomes an
# impl-only adios module.
{ ... }:

{
  options = { };

  impl = { ... }: {
    # Enable systemd as the default service manager for the base system.
    # This ensures system.build.toplevel uses systemd by default.
    # TODO(adios-cutover): priority lost (was mkDefault).
    serviceManager.systemd.enable = true;

    # Note: The serviceManager.<name>.enable options are internal implementation details.
    # Users should select service managers by choosing the appropriate build attribute:
    #   - config.system.build.systemd  (systemd variant)
    #   - config.system.build.runit    (runit variant)
    #   - config.system.build.launchd  (stub)
    #   - config.system.build.rcd      (stub)
    #
    # The default system.build.toplevel uses systemd (set here via mkDefault).
  };
}
