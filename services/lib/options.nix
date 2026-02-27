# Common service options shared across all service managers
{ lib }:

let
  inherit (lib)
    types
    mkOption
    mkEnableOption
    literalExpression
    ;
  serviceTypes = import ./types.nix { inherit lib; };
in
{
  # Core options that work across all service managers
  commonOptions = {
    enable = mkEnableOption "the service";

    description = mkOption {
      type = types.str;
      example = "Example web server";
      description = ''
        A short, human-readable description of the service.
        Used in service manager UIs and status output.
      '';
    };

    command = mkOption {
      type = serviceTypes.command;
      example = literalExpression ''"''${pkgs.nginx}/bin/nginx"'';
      description = ''
        The main command to execute for this service.
        Should be an absolute path to an executable.
      '';
    };

    args = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "-c"
        "/etc/nginx/nginx.conf"
      ];
      description = ''
        Arguments to pass to the command.
      '';
    };

    workingDirectory = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/var/lib/myservice";
      description = ''
        Working directory for the service process.
      '';
    };

    user = mkOption {
      type = types.str;
      default = "root";
      example = "nginx";
      description = ''
        User account under which the service runs.
      '';
    };

    group = mkOption {
      type = types.str;
      default = "root";
      example = "nginx";
      description = ''
        Primary group for the service process.
      '';
    };

    environment = mkOption {
      type = types.attrsOf serviceTypes.envValue;
      default = { };
      example = literalExpression ''
        {
          LANG = "en_US.UTF-8";
          CONFIG_DIR = "/etc/myservice";
        }
      '';
      description = ''
        Environment variables for the service.
      '';
    };

    path = mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = literalExpression "[ pkgs.coreutils pkgs.gnugrep ]";
      description = ''
        Packages to add to the service's PATH.
      '';
    };

    restartPolicy = mkOption {
      type = serviceTypes.restartPolicy;
      default = "on-failure";
      description = ''
        When to restart the service:
        - always: Always restart
        - on-failure: Restart on non-zero exit
        - on-abnormal: Restart on signal/timeout/watchdog
        - on-abort: Restart on unhandled signal
        - on-watchdog: Restart on watchdog timeout
        - never: Never restart
      '';
    };

    preStart = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Shell commands to run before starting the main process.
      '';
    };

    postStart = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Shell commands to run after the main process starts.
        Warning: Not supported on all service managers.
      '';
    };

    postStop = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Shell commands to run after the service stops.
      '';
    };
  };
}
