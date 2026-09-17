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
    name: service: (service.enable or false) == true && (service.command or null) != null
  ) config.services;

  # Filter to only include enabled user services with command set
  enabledUserServices = filterAttrs (
    name: service: service.enable == true && service.command != null
  ) config.users.services;

  # Generate a systemd unit file for a service
  mkSystemdUnit =
    name: serviceCfg:
    let
      # Map restartPolicy to systemd Restart directive
      restartValue =
        {
          always = "always";
          on-failure = "on-failure";
          never = "no";
        }
        .${serviceCfg.restartPolicy or "always"} or "always";

      # Build command with args
      execStart =
        if (serviceCfg.args or [ ]) == [ ] then
          serviceCfg.command
        else
          "${serviceCfg.command} ${concatStringsSep " " serviceCfg.args}";

      # Environment variables
      envVars = mapAttrsToList (k: v: "Environment=\"${k}=${v}\"") (serviceCfg.environment or { });

      # Systemd-specific options
      systemdCfg = serviceCfg.systemd or { };

      # Dependencies
      after = systemdCfg.after or [ ];
      wants = systemdCfg.wants or [ ];
      requires = systemdCfg.requires or [ ];
      before = systemdCfg.before or [ ];
      wantedBy = systemdCfg.wantedBy or [ "multi-user.target" ];

      # Service config overrides
      serviceConfig = systemdCfg.serviceConfig or { };

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
        ${optionalString (
          (serviceCfg.preStart or "") != ""
        ) "ExecStartPre=${pkgs.writeShellScript "${name}-prestart" serviceCfg.preStart}"}
        ${optionalString (
          (serviceCfg.postStart or "") != ""
        ) "ExecStartPost=${pkgs.writeShellScript "${name}-poststart" serviceCfg.postStart}"}
        ${optionalString (
          (serviceCfg.postStop or "") != ""
        ) "ExecStopPost=${pkgs.writeShellScript "${name}-poststop" serviceCfg.postStop}"}
        Restart=${restartValue}
        ${optionalString (serviceCfg.user or null != null) "User=${serviceCfg.user}"}
        ${optionalString (serviceCfg.group or null != null) "Group=${serviceCfg.group}"}
        ${optionalString (
          serviceCfg.workingDirectory or null != null
        ) "WorkingDirectory=${serviceCfg.workingDirectory}"}
        ${concatStringsSep "\n" envVars}
        ${concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${toString v}") serviceConfig)}

        [Install]
        ${concatMapStringsSep "\n" (t: "WantedBy=${t}") wantedBy}
      '';
    };

  # Generate all systemd units
  systemdUnits = mapAttrs mkSystemdUnit enabledServices;

  # Generate a systemd user unit file for a user service
  mkUserSystemdUnit =
    name: serviceCfg:
    let
      restartValue =
        {
          always = "always";
          on-failure = "on-failure";
          never = "no";
        }
        .${serviceCfg.restartPolicy} or "always";

      execStart =
        if serviceCfg.args == [ ] then
          serviceCfg.command
        else
          "${serviceCfg.command} ${concatStringsSep " " serviceCfg.args}";

      envVars = mapAttrsToList (k: v: "Environment=\"${k}=${v}\"") serviceCfg.environment;

      systemdCfg = serviceCfg.systemd;

      after = systemdCfg.after or [ ];
      wants = systemdCfg.wants or [ ];
      requires = systemdCfg.requires or [ ];
      before = systemdCfg.before or [ ];
      wantedBy = systemdCfg.wantedBy or [ "default.target" ];

      serviceConfig = systemdCfg.serviceConfig or { };

    in
    pkgs.writeTextFile {
      name = "${name}.service";
      text = ''
        [Unit]
        Description=${serviceCfg.description}
        ${concatMapStringsSep "\n" (d: "After=${d}") after}
        ${concatMapStringsSep "\n" (d: "Wants=${d}") wants}
        ${concatMapStringsSep "\n" (d: "Requires=${d}") requires}
        ${concatMapStringsSep "\n" (d: "Before=${d}") before}

        [Service]
        Type=${serviceConfig.Type or "simple"}
        ExecStart=${execStart}
        ${optionalString (
          serviceCfg.preStart != ""
        ) "ExecStartPre=${pkgs.writeShellScript "${name}-prestart" serviceCfg.preStart}"}
        ${optionalString (
          serviceCfg.postStart != ""
        ) "ExecStartPost=${pkgs.writeShellScript "${name}-poststart" serviceCfg.postStart}"}
        ${optionalString (
          serviceCfg.postStop != ""
        ) "ExecStopPost=${pkgs.writeShellScript "${name}-poststop" serviceCfg.postStop}"}
        Restart=${restartValue}
        ${optionalString (
          serviceCfg.workingDirectory != null
        ) "WorkingDirectory=${serviceCfg.workingDirectory}"}
        ${concatStringsSep "\n" envVars}
        ${concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${toString v}") serviceConfig)}

        [Install]
        ${concatMapStringsSep "\n" (t: "WantedBy=${t}") wantedBy}
      '';
    };

  # Generate all user systemd units
  userSystemdUnits = mapAttrs mkUserSystemdUnit enabledUserServices;

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

        # Copy user systemd unit files
        (listToAttrs (
          map (
            name:
            nameValuePair "systemd/user/${name}.service" {
              source = userSystemdUnits.${name};
            }
          ) (attrNames userSystemdUnits)
        ))

        # Default systemd configuration
        {
          "systemd/system.conf".text = ''
            [Manager]
            DefaultTimeoutStartSec=90s
            DefaultTimeoutStopSec=90s
          '';
        }

        # Preset policy: disable services that require extra configuration or
        # dependencies not present in a minimal ekaos system.  The 00- prefix
        # gives this file higher priority than the upstream 90-systemd.preset.
        {
          "systemd/system-preset/00-ekaos.preset".text = ''
            # Core services we always want
            enable systemd-journald.service
            enable systemd-udevd.service
            enable systemd-tmpfiles-setup.service
            enable systemd-sysctl.service
            enable getty@.service
            enable serial-getty@.service

            # Disable services that fail or hang without extra configuration
            disable systemd-firstboot.service
            disable systemd-resolved.service
            disable systemd-timesyncd.service
            disable systemd-networkd.service
            disable systemd-networkd-wait-online.service
            disable systemd-homed.service
            disable systemd-homed-activate.service
            disable systemd-userdbd.socket
            disable systemd-nsresourced.socket
            disable systemd-oomd.service
            disable systemd-oomd.socket
            disable systemd-sysext.service
            disable systemd-confext.service
            disable systemd-pstore.service
            disable systemd-boot-update.service
            disable systemd-boot-clear-sysfail.service
            disable systemd-network-generator.service
            disable systemd-mountfsd.socket
            disable systemd-tpm2-clear.service
            disable systemd-pcrlock-firmware-code.service
            disable systemd-pcrlock-firmware-config.service
            disable systemd-pcrlock-file-system.service
            disable systemd-pcrlock-machine-id.service
            disable systemd-pcrlock-secureboot-authority.service
            disable systemd-pcrlock-secureboot-policy.service
            disable systemd-pcrlock-make-policy.service

            # Let remaining services use upstream defaults
          '';
        }

        # Install essential systemd targets and units from the systemd package.
        # Units live under example/ in the package (moved from lib/ during build).
        (
          let
            sysDir = "${cfg.package}/example/systemd/system";
            targets = [
              # Boot chain: sysinit → basic → multi-user
              "sysinit.target"
              "basic.target"
              "multi-user.target"
              # Filesystem targets
              "local-fs.target"
              "local-fs-pre.target"
              "remote-fs.target"
              "remote-fs-pre.target"
              "swap.target"
              # Service targets
              "sockets.target"
              "timers.target"
              "paths.target"
              "slices.target"
              "network.target"
              "network-online.target"
              "network-pre.target"
              # Recovery / power
              "rescue.target"
              "emergency.target"
              "shutdown.target"
              "halt.target"
              "poweroff.target"
              "reboot.target"
              # Getty
              "getty.target"
              "getty-pre.target"
            ];
          in
          lib.listToAttrs (
            map (t: lib.nameValuePair "systemd/system/${t}" { source = "${sysDir}/${t}"; }) targets
          )
          // {
            "systemd/system/default.target".source = "${sysDir}/${cfg.defaultTarget}";
          }
        )
      ];

      # Make all packaged systemd units discoverable at runtime.
      # The systemd package moves units from lib/ to example/ during build;
      # adding example/systemd/system to the search path lets systemd find
      # services, sockets, and other units it ships (journald, udevd, etc.).
      boot.extraSystemdUnitPaths = [ "${cfg.package}/example/systemd/system" ];

      # Expose systemd options for backward compatibility
      systemd.package = cfg.package;
      systemd.defaultTarget = cfg.defaultTarget;
    }
  ]);
}
