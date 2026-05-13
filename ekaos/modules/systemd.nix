# Systemd integration for ekaos
# Consumes services.* definitions and generates systemd unit files
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  # Filter to only include enabled services with command set
  enabledServices = filterAttrs (
    name: service:
      (service.enable or false) == true
      && (service.command or null) != null
  ) config.services;

  # Generate a systemd unit file for a service
  mkSystemdUnit = name: cfg:
    let
      # Map restartPolicy to systemd Restart directive
      restartValue = {
        always = "always";
        on-failure = "on-failure";
        never = "no";
      }.${cfg.restartPolicy or "always"} or "always";

      # Build command with args
      execStart = if (cfg.args or []) == []
                  then cfg.command
                  else "${cfg.command} ${concatStringsSep " " cfg.args}";

      # Environment variables
      envVars = mapAttrsToList (k: v: "Environment=\"${k}=${v}\"") (cfg.environment or {});

      # Systemd-specific options
      systemdCfg = cfg.systemd or {};

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
        Description=${cfg.description or name}
        ${concatMapStringsSep "\n" (d: "After=${d}") after}
        ${concatMapStringsSep "\n" (d: "Wants=${d}") wants}
        ${concatMapStringsSep "\n" (d: "Requires=${d}") requires}
        ${concatMapStringsSep "\n" (d: "Before=${d}") before}

        [Service]
        Type=${serviceConfig.Type or "simple"}
        ExecStart=${execStart}
        ${optionalString ((cfg.preStart or "") != "") "ExecStartPre=${pkgs.writeShellScript "${name}-prestart" cfg.preStart}"}
        ${optionalString ((cfg.postStart or "") != "") "ExecStartPost=${pkgs.writeShellScript "${name}-poststart" cfg.postStart}"}
        ${optionalString ((cfg.postStop or "") != "") "ExecStopPost=${pkgs.writeShellScript "${name}-poststop" cfg.postStop}"}
        Restart=${restartValue}
        ${optionalString (cfg.user or null != null) "User=${cfg.user}"}
        ${optionalString (cfg.group or null != null) "Group=${cfg.group}"}
        ${optionalString (cfg.workingDirectory or null != null) "WorkingDirectory=${cfg.workingDirectory}"}
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
  options = {
    # No options defined here - service modules define their own options
    # at services.* or systemd.services.* as needed

    systemd.package = mkOption {
      type = types.package;
      default = pkgs.systemd;
      description = "The systemd package to use.";
    };

    systemd.defaultTarget = mkOption {
      type = types.str;
      default = "multi-user.target";
      description = "The default systemd target to boot into.";
    };
  };

  config = {
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
          "${config.systemd.package}/lib/systemd/system/multi-user.target";
        "systemd/system/sysinit.target".source =
          "${config.systemd.package}/lib/systemd/system/sysinit.target";
        "systemd/system/basic.target".source = "${config.systemd.package}/lib/systemd/system/basic.target";
        "systemd/system/sockets.target".source =
          "${config.systemd.package}/lib/systemd/system/sockets.target";
        "systemd/system/timers.target".source =
          "${config.systemd.package}/lib/systemd/system/timers.target";
        "systemd/system/paths.target".source = "${config.systemd.package}/lib/systemd/system/paths.target";
        "systemd/system/local-fs.target".source =
          "${config.systemd.package}/lib/systemd/system/local-fs.target";
        "systemd/system/remote-fs.target".source =
          "${config.systemd.package}/lib/systemd/system/remote-fs.target";
        "systemd/system/default.target".source =
          "${config.systemd.package}/lib/systemd/system/${config.systemd.defaultTarget}";
      }
    ];

    # No need to define systemd.services here - individual modules
    # define their own services at services.* or systemd.services.* as needed
  };
}
