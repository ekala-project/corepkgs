# User-scoped service definitions
# Services defined here run in each user's service manager instance
# (e.g., systemd --user) rather than as system services.
{ lib, ... }:

with lib;

let
  userServiceOpts =
    { name, ... }:
    {
      options = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to enable this user service.";
        };

        description = mkOption {
          type = types.str;
          default = name;
          description = "Service description.";
        };

        command = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Command to run.";
        };

        args = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Command arguments.";
        };

        environment = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Environment variables for the service.";
        };

        restartPolicy = mkOption {
          type = types.enum [
            "always"
            "on-failure"
            "never"
          ];
          default = "always";
          description = "Restart policy for the service.";
        };

        preStart = mkOption {
          type = types.lines;
          default = "";
          description = "Script to run before starting the service.";
        };

        postStart = mkOption {
          type = types.lines;
          default = "";
          description = "Script to run after the service starts.";
        };

        postStop = mkOption {
          type = types.lines;
          default = "";
          description = "Script to run after the service stops.";
        };

        workingDirectory = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Working directory for the service.";
        };

        systemd = mkOption {
          type = types.attrsOf types.anything;
          default = { };
          description = ''
            Systemd-specific options for user units.
            Default wantedBy is ["default.target"].
          '';
        };

        runit = mkOption {
          type = types.attrsOf types.anything;
          default = { };
          description = "Runit-specific options for user services.";
        };
      };
    };

in

{
  options.users.services = mkOption {
    type = types.attrsOf (types.submodule userServiceOpts);
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
}
