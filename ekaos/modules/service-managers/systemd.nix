# Systemd service manager for ekaos
# Consumes services.* definitions and generates systemd unit files
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.serviceManager.systemd;

  # Filter to only include enabled services with command set
  enabledServices = filterAttrs (
    name: service:
      (service.enable or false) == true
      && (service.command or null) != null
  ) config.services;

  # Generate a systemd unit file for a service
  mkSystemdUnit = name: serviceCfg:
    let
      # Map restartPolicy to systemd Restart directive
      restartValue = {
        always = "always";
        on-failure = "on-failure";
        never = "no";
      }.${serviceCfg.restartPolicy or "always"} or "always";

      # Build command with args
      execStart = if (serviceCfg.args or []) == []
                  then serviceCfg.command
                  else "${serviceCfg.command} ${concatStringsSep " " serviceCfg.args}";

      # Environment variables
      envVars = mapAttrsToList (k: v: "Environment=\"${k}=${v}\"") (serviceCfg.environment or {});

      # Systemd-specific options
      systemdCfg = serviceCfg.systemd or {};

      # Dependencies
      after = systemdCfg.after or [];
      wants = systemdCfg.wants or [];
      requires = systemdCfg.requires or [];
      before = systemdCfg.before or [];
      wantedBy = systemdCfg.wantedBy or [ "multi-user.target" ];

      # Service config overrides
      serviceConfig = systemdCfg.serviceConfig or {};

    in
    pkgs.writeTextFile {
      name = "${name}.service";
      text = ''
        [Unit]
        Description=${serviceCfg.description or name}
        ${concatMapStringsSep "\n" (d: "After=${d}") after}
        ${concatMapStringsSep "\n" (d: "Wants=${d}") wants}
        ${concatMapStringsSep "\n" (d: "Requires=${d}") requires}
        ${concatMapStringsSep "\n" (d: "Before=${d}") before}

        [Service]
        Type=${serviceConfig.Type or "simple"}
        ExecStart=${execStart}
        ${optionalString ((serviceCfg.preStart or "") != "") "ExecStartPre=${pkgs.writeShellScript "${name}-prestart" serviceCfg.preStart}"}
        ${optionalString ((serviceCfg.postStart or "") != "") "ExecStartPost=${pkgs.writeShellScript "${name}-poststart" serviceCfg.postStart}"}
        ${optionalString ((serviceCfg.postStop or "") != "") "ExecStopPost=${pkgs.writeShellScript "${name}-poststop" serviceCfg.postStop}"}
        Restart=${restartValue}
        ${optionalString (serviceCfg.user or null != null) "User=${serviceCfg.user}"}
        ${optionalString (serviceCfg.group or null != null) "Group=${serviceCfg.group}"}
        ${optionalString (serviceCfg.workingDirectory or null != null) "WorkingDirectory=${serviceCfg.workingDirectory}"}
        ${concatStringsSep "\n" envVars}
        ${concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${toString v}") serviceConfig)}

        [Install]
        ${concatMapStringsSep "\n" (t: "WantedBy=${t}") wantedBy}
      '';
    };

  # Generate all systemd units
  systemdUnits = mapAttrs mkSystemdUnit enabledServices;

in

{
  options.serviceManager.systemd = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable systemd as the service manager";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.systemd;
      description = "The systemd package to use.";
    };

    defaultTarget = mkOption {
      type = types.str;
      default = "multi-user.target";
      description = "The default systemd target to boot into.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Mutual exclusion assertions
    {
      assertions = [
        {
          assertion = !(config.serviceManager.runit.enable or false);
          message = "Cannot enable both systemd and runit service managers. Only one service manager can be enabled at a time.";
        }
        {
          assertion = !(config.serviceManager.launchd.enable or false);
          message = "Cannot enable both systemd and launchd service managers. Only one service manager can be enabled at a time.";
        }
        {
          assertion = !(config.serviceManager.rcd.enable or false);
          message = "Cannot enable both systemd and rcd service managers. Only one service manager can be enabled at a time.";
        }
      ];
    }

    # Systemd configuration
    {
      # Add systemd units to /etc
      environment.etc = mkMerge [
        # Copy systemd unit files
        (listToAttrs (
          map (
            name:
            nameValuePair "systemd/system/${name}.service" {
              source = systemdUnits.${name};
            }
          ) (attrNames systemdUnits)
        ))

        # Default systemd configuration
        {
          "systemd/system.conf".text = ''
            [Manager]
            DefaultTimeoutStartSec=90s
            DefaultTimeoutStopSec=90s
          '';
        }

        # Create symlinks for essential systemd targets
        {
          "systemd/system/multi-user.target".source =
            "${cfg.package}/lib/systemd/system/multi-user.target";
          "systemd/system/sysinit.target".source =
            "${cfg.package}/lib/systemd/system/sysinit.target";
          "systemd/system/basic.target".source = "${cfg.package}/lib/systemd/system/basic.target";
          "systemd/system/sockets.target".source =
            "${cfg.package}/lib/systemd/system/sockets.target";
          "systemd/system/timers.target".source =
            "${cfg.package}/lib/systemd/system/timers.target";
          "systemd/system/paths.target".source = "${cfg.package}/lib/systemd/system/paths.target";
          "systemd/system/local-fs.target".source =
            "${cfg.package}/lib/systemd/system/local-fs.target";
          "systemd/system/remote-fs.target".source =
            "${cfg.package}/lib/systemd/system/remote-fs.target";
          "systemd/system/default.target".source =
            "${cfg.package}/lib/systemd/system/${cfg.defaultTarget}";
        }
      ];

      # Expose systemd options for backward compatibility
      systemd.package = cfg.package;
      systemd.defaultTarget = cfg.defaultTarget;
    }
  ]);
}
