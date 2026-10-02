# User-scoped service definitions
# Services defined here run in each user's service manager instance
# (e.g., systemd --user) rather than as system services.
#
# Uses the same service option interface as services.* (from
# services/lib/service-module.nix) for consistency. The service
# managers ignore the user/group fields for user services since
# they run as the logged-in user.
{ lib, pkgs, ... }:

let
  serviceLib = import ../../../services/lib/service-module.nix { inherit lib pkgs; };
in

{
  options.users.services = serviceLib.mkServicesOption // {
    description = ''
      Per-user service definitions.

      These services run in each user's service manager instance
      (e.g., systemd user units at /etc/systemd/user/) rather than
      as system-level services. They apply to all users at login.

      Same option interface as services.* — the user/group fields
      are ignored (the service runs as the logged-in user).
    '';
  };
}
