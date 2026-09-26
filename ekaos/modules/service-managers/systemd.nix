# Adios port of ekaos/modules/service-managers/systemd.nix.
#
# Tree path: service-managers/systemd is parent.systemd.
# Consumes service definitions and generates systemd unit files under
# /etc/systemd/system/ and /etc/systemd/user/, plus default manager
# config, target symlinks, and the backward-compat systemd.package /
# systemd.defaultTarget values. Unit builders close over pkgs in the
# top-level let (impl only sees { options, inputs }).
# TODO(adios-cutover): AGGREGATION GAP (load-bearing). Legacy filters
# enabled services out of ALL of config.services / config.users.services
# via the global fixpoint. Adios inputs resolve to whatever the tree
# wires at parent.services / parent.config."user-services"; arbitrary
# service modules outside the tree are invisible and their units are
# silently missing.
# TODO(adios-cutover): mutual-exclusion assertions are guarded by
# `!options.enable || ...` (legacy evaluated them only when enabled).
{ types, pkgs, ... }:

let
  filterAttrs =
    pred: set:
    builtins.listToAttrs (
      builtins.map (n: {
        name = n;
        value = set.${n};
      }) (builtins.filter (n: pred n set.${n}) (builtins.attrNames set))
    );
  mapAttrsToList = f: attrs: builtins.map (n: f n attrs.${n}) (builtins.attrNames attrs);

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
          "${serviceCfg.command} ${builtins.concatStringsSep " " serviceCfg.args}";

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
        ${builtins.concatStringsSep "\n" (builtins.map (d: "After=${d}") after)}
        ${builtins.concatStringsSep "\n" (builtins.map (d: "Wants=${d}") wants)}
        ${builtins.concatStringsSep "\n" (builtins.map (d: "Requires=${d}") requires)}
        ${builtins.concatStringsSep "\n" (builtins.map (d: "Before=${d}") before)}

        [Service]
        Type=${serviceConfig.Type or "simple"}
        ExecStart=${execStart}
        ${
          if ((serviceCfg.preStart or "") != "") then
            "ExecStartPre=${pkgs.writeShellScript "${name}-prestart" serviceCfg.preStart}"
          else
            ""
        }
        ${
          if ((serviceCfg.postStart or "") != "") then
            "ExecStartPost=${pkgs.writeShellScript "${name}-poststart" serviceCfg.postStart}"
          else
            ""
        }
        ${
          if ((serviceCfg.postStop or "") != "") then
            "ExecStopPost=${pkgs.writeShellScript "${name}-poststop" serviceCfg.postStop}"
          else
            ""
        }
        Restart=${restartValue}
        ${if ((serviceCfg.user or null) != null) then "User=${serviceCfg.user}" else ""}
        ${if ((serviceCfg.group or null) != null) then "Group=${serviceCfg.group}" else ""}
        ${
          if ((serviceCfg.workingDirectory or null) != null) then
            "WorkingDirectory=${serviceCfg.workingDirectory}"
          else
            ""
        }
        ${builtins.concatStringsSep "\n" envVars}
        ${builtins.concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${toString v}") serviceConfig)}

        [Install]
        ${builtins.concatStringsSep "\n" (builtins.map (t: "WantedBy=${t}") wantedBy)}
      '';
    };

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
          "${serviceCfg.command} ${builtins.concatStringsSep " " serviceCfg.args}";

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
        ${builtins.concatStringsSep "\n" (builtins.map (d: "After=${d}") after)}
        ${builtins.concatStringsSep "\n" (builtins.map (d: "Wants=${d}") wants)}
        ${builtins.concatStringsSep "\n" (builtins.map (d: "Requires=${d}") requires)}
        ${builtins.concatStringsSep "\n" (builtins.map (d: "Before=${d}") before)}

        [Service]
        Type=${serviceConfig.Type or "simple"}
        ExecStart=${execStart}
        ${
          if serviceCfg.preStart != "" then
            "ExecStartPre=${pkgs.writeShellScript "${name}-prestart" serviceCfg.preStart}"
          else
            ""
        }
        ${
          if serviceCfg.postStart != "" then
            "ExecStartPost=${pkgs.writeShellScript "${name}-poststart" serviceCfg.postStart}"
          else
            ""
        }
        ${
          if serviceCfg.postStop != "" then
            "ExecStartPost=${pkgs.writeShellScript "${name}-poststop" serviceCfg.postStop}"
          else
            ""
        }
        Restart=${restartValue}
        ${
          if serviceCfg.workingDirectory != null then
            "WorkingDirectory=${serviceCfg.workingDirectory}"
          else
            ""
        }
        ${builtins.concatStringsSep "\n" envVars}
        ${builtins.concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${toString v}") serviceConfig)}

        [Install]
        ${builtins.concatStringsSep "\n" (builtins.map (t: "WantedBy=${t}") wantedBy)}
      '';
    };
in

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Enable systemd as the service manager";
    };

    package = {
      type = types.derivation;
      default = pkgs.systemd;
      description = "The systemd package to use.";
    };

    defaultTarget = {
      type = types.string;
      default = "multi-user.target";
      description = "The default systemd target to boot into.";
    };
  };

  inputs = {
    services.from = { root }: root.services;
    userServices.from = { root }: root.config."user-services";
    runitMgr.from = { parent }: parent.runit;
    launchdMgr.from = { parent }: parent.launchd;
    rcdMgr.from = { parent }: parent.rcd;
  };

  assertions = [
    {
      verify = { options, inputs }: !options.enable || !(inputs.runitMgr.enable or false);
      explain =
        { options, inputs }:
        "Cannot enable both systemd and runit service managers. Only one service manager can be enabled at a time.";
    }
    {
      verify = { options, inputs }: !options.enable || !(inputs.launchdMgr.enable or false);
      explain =
        { options, inputs }:
        "Cannot enable both systemd and launchd service managers. Only one service manager can be enabled at a time.";
    }
    {
      verify = { options, inputs }: !options.enable || !(inputs.rcdMgr.enable or false);
      explain =
        { options, inputs }:
        "Cannot enable both systemd and rcd service managers. Only one service manager can be enabled at a time.";
    }
  ];

  impl =
    { options, inputs }:
    let
      # Filter to only include enabled services with command set
      enabledServices = filterAttrs (
        name: service: (service.enable or false) == true && (service.command or null) != null
      ) inputs.services;

      # Filter to only include enabled user services with command set
      enabledUserServices = filterAttrs (
        name: service: service.enable == true && service.command != null
      ) inputs.userServices.users.services;

      # Generate all systemd units
      systemdUnits = builtins.mapAttrs mkSystemdUnit enabledServices;

      # Generate all user systemd units
      userSystemdUnits = builtins.mapAttrs mkUserSystemdUnit enabledUserServices;
    in
    if !options.enable then
      { }
    else
      {
        # Add systemd units to /etc
        environment.etc =
          # Copy systemd unit files
          builtins.listToAttrs (
            builtins.map (name: {
              name = "systemd/system/${name}.service";
              value = {
                source = systemdUnits.${name};
              };
            }) (builtins.attrNames systemdUnits)
          )
          // builtins.listToAttrs (
            builtins.map (name: {
              name = "systemd/user/${name}.service";
              value = {
                source = userSystemdUnits.${name};
              };
            }) (builtins.attrNames userSystemdUnits)
          )
          // {
            # Default systemd configuration
            "systemd/system.conf".text = ''
              [Manager]
              DefaultTimeoutStartSec=90s
              DefaultTimeoutStopSec=90s
            '';
          }
          // {
            # Create symlinks for essential systemd targets
            "systemd/system/multi-user.target".source =
              "${options.package}/lib/systemd/system/multi-user.target";
            "systemd/system/sysinit.target".source = "${options.package}/lib/systemd/system/sysinit.target";
            "systemd/system/basic.target".source = "${options.package}/lib/systemd/system/basic.target";
            "systemd/system/sockets.target".source = "${options.package}/lib/systemd/system/sockets.target";
            "systemd/system/timers.target".source = "${options.package}/lib/systemd/system/timers.target";
            "systemd/system/paths.target".source = "${options.package}/lib/systemd/system/paths.target";
            "systemd/system/local-fs.target".source = "${options.package}/lib/systemd/system/local-fs.target";
            "systemd/system/remote-fs.target".source = "${options.package}/lib/systemd/system/remote-fs.target";
            "systemd/system/default.target".source =
              "${options.package}/lib/systemd/system/${options.defaultTarget}";
          };

        # Expose systemd options for backward compatibility
        systemd.package = options.package;
        systemd.defaultTarget = options.defaultTarget;
      };
}
