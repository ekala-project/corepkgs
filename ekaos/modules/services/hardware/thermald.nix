# Intel thermal management daemon
# Ported from nixpkgs/nixos/modules/services/hardware/thermald.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.thermald;
in
{
  options.services.thermald = {
    enable = lib.mkEnableOption "thermald, the temperature management daemon";

    description = lib.mkOption {
      type = lib.types.str;
      default = "Thermal Daemon Service";
      description = "Service description.";
    };

    command = lib.mkOption {
      type = lib.types.str;
      internal = true;
      description = "Command to run (set automatically).";
    };

    args = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
      default = [ ];
      description = "Command arguments (set automatically).";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "root";
      description = "User to run service as.";
    };

    restartPolicy = lib.mkOption {
      type = lib.types.str;
      default = "always";
      description = "Restart policy.";
    };

    systemd = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Systemd-specific options.";
    };

    debug = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable debug logging.";
    };

    ignoreCpuidCheck = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to ignore the cpuid check to allow running on unsupported platforms.";
    };

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        The thermald manual configuration file.

        Leave unspecified to run with adaptive mode which uses
        your computer's DPTF adaptive tables.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.thermald or (throw "thermald package not available");
      defaultText = lib.literalExpression "pkgs.thermald";
      description = "The thermald package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.dbus.packages = [ cfg.package ];

    services.thermald = {
      command = "${cfg.package}/sbin/thermald";
      args = [
        "--no-daemon"
        "--dbus-enable"
      ]
      ++ lib.optionals cfg.debug [ "--loglevel=debug" ]
      ++ lib.optionals cfg.ignoreCpuidCheck [ "--ignore-cpuid-check" ]
      ++ (
        if cfg.configFile != null then
          [
            "--config-file"
            (toString cfg.configFile)
          ]
        else
          [ "--adaptive" ]
      );
      systemd = {
        wantedBy = [ "multi-user.target" ];
      };
    };
  };
}
