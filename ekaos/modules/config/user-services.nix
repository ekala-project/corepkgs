# Adios port of ekaos/modules/config/user-services.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
#
# User-scoped service definitions: services defined here run in each user's
# service manager instance (e.g., systemd --user) rather than as system
# services. This module declares options only; it has no config section.
{ types, ... }:

{
  options = {
    services = {
      # TODO(adios-cutover): submodule validation lost. Legacy validated each
      # service (enable, description defaulting to the service name, command,
      # args, environment, restartPolicy always/on-failure/never, preStart,
      # postStart, postStop, workingDirectory, systemd and runit attrsets).
      type = types.attrsOf types.attrs;
      default = { };
      description = ''
        Per-user service definitions.

        These services run in each user's service manager instance
        (e.g., systemd user units at /etc/systemd/user/) rather than
        as system-level services. They apply to all users at login.

        Same interface as services.* but without user/group fields
        (the service runs as the logged-in user).
      '';
    };
  };

  impl = { ... }: { };
}
