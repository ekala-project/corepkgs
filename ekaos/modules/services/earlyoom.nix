# Adios port of ekaos/modules/services/earlyoom.nix.
# TODO(adios-cutover): command/args were internal options set by the legacy
# config; they are computed in impl, not user options.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable earlyoom, the early OOM daemon.

        earlyoom monitors memory and swap usage and kills the largest
        process when thresholds are exceeded, preventing the system
        from becoming unresponsive due to OOM conditions.
      '';
    };

    package = {
      type = types.nullOr types.derivation;
      default = pkgs.earlyoom or null;
      description = "The earlyoom package to use.";
    };

    description = {
      type = types.string;
      default = "Early OOM Daemon";
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

    freeMemThreshold = {
      type = types.int;
      default = 10;
      description = ''
        Minimum percentage of free memory before earlyoom starts killing.
      '';
    };

    freeSwapThreshold = {
      type = types.int;
      default = 10;
      description = ''
        Minimum percentage of free swap before earlyoom starts killing.
      '';
    };

    freeMemKillThreshold = {
      type = types.nullOr types.int;
      default = null;
      description = ''
        Send SIGKILL when free memory drops below this percentage.
        Defaults to half of freeMemThreshold.
      '';
    };

    freeSwapKillThreshold = {
      type = types.nullOr types.int;
      default = null;
      description = ''
        Send SIGKILL when free swap drops below this percentage.
        Defaults to half of freeSwapThreshold.
      '';
    };

    enableNotifications = {
      type = types.bool;
      default = false;
      description = "Whether to send D-Bus notifications on kills.";
    };

    extraArgs = {
      type = types.listOf types.string;
      default = [ ];
      description = "Additional arguments passed to earlyoom.";
    };
  };

  assertions = [
    {
      verify = { options, ... }: (!options.enable) || (options.package != null);
      explain =
        { options, ... }: "package option must be set when enabled (earlyoom is not in core-pkgs)";
    }
  ];

  impl =
    { options, ... }:
    if !options.enable then
      { }
    else
      {
        services.earlyoom = {
          inherit (options)
            enable
            description
            user
            restartPolicy
            ;
          command = "${options.package}/bin/earlyoom";
          args = [
            "-m"
            (toString options.freeMemThreshold)
            "-s"
            (toString options.freeSwapThreshold)
          ]
          ++ (
            if options.freeMemKillThreshold != null then
              [
                "-M"
                (toString options.freeMemKillThreshold)
              ]
            else
              [ ]
          )
          ++ (
            if options.freeSwapKillThreshold != null then
              [
                "-S"
                (toString options.freeSwapKillThreshold)
              ]
            else
              [ ]
          )
          ++ (if options.enableNotifications then [ "-n" ] else [ ])
          ++ options.extraArgs;
          systemd = {
            after = [ "multi-user.target" ];
            wantedBy = [ "multi-user.target" ];
          }
          // options.systemd;
        };
      };
}
