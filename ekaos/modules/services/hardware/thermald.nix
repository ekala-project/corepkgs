# Adios port of ekaos/modules/services/hardware/thermald.nix.
# TODO(adios-cutover): command/args were internal options set by the legacy
# config; they are computed in impl, not user options.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Whether to enable thermald, the temperature management daemon.";
    };

    description = {
      type = types.string;
      default = "Thermal Daemon Service";
      description = "Service description.";
    };

    user = {
      type = types.string;
      default = "root";
      description = "User to run service as.";
    };

    restartPolicy = {
      type = types.string;
      default = "always";
      description = "Restart policy.";
    };

    systemd = {
      type = types.attrsOf types.any;
      default = { };
      description = "Systemd-specific options.";
    };

    debug = {
      type = types.bool;
      default = false;
      description = "Whether to enable debug logging.";
    };

    ignoreCpuidCheck = {
      type = types.bool;
      default = false;
      description = "Whether to ignore the cpuid check to allow running on unsupported platforms.";
    };

    configFile = {
      type = types.nullOr types.pathLike;
      default = null;
      description = ''
        The thermald manual configuration file.

        Leave unspecified to run with adaptive mode which uses
        your computer's DPTF adaptive tables.
      '';
    };

    package = {
      type = types.nullOr types.derivation;
      default = pkgs.thermald or null;
      description = "The thermald package to use.";
    };
  };

  assertions = [
    {
      verify = { options, ... }: (!options.enable) || (options.package != null);
      explain =
        { options, ... }: "package option must be set when enabled (thermald is not in core-pkgs)";
    }
  ];

  impl =
    { options, ... }:
    if !options.enable then
      { }
    else
      {
        services.dbus.packages = [ options.package ];

        services.thermald = {
          inherit (options)
            enable
            description
            user
            restartPolicy
            ;
          command = "${options.package}/sbin/thermald";
          args = [
            "--no-daemon"
            "--dbus-enable"
          ]
          ++ (if options.debug then [ "--loglevel=debug" ] else [ ])
          ++ (if options.ignoreCpuidCheck then [ "--ignore-cpuid-check" ] else [ ])
          ++ (
            if options.configFile != null then
              [
                "--config-file"
                (toString options.configFile)
              ]
            else
              [ "--adaptive" ]
          );
          systemd = {
            wantedBy = [ "multi-user.target" ];
          }
          // options.systemd;
        };
      };
}
