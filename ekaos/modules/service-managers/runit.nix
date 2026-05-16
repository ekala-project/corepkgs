# Runit service manager for ekaos
# Consumes services.* definitions and generates runit service directories
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.serviceManager.runit;

  # Filter to only include enabled services with command set
  enabledServices = filterAttrs (
    name: service: (service.enable or false) == true && (service.command or null) != null
  ) config.services;

  # Generate a runit service directory for a service
  mkRunitService =
    name: serviceCfg:
    let
      # Build command with args
      execCommand =
        if (serviceCfg.args or [ ]) == [ ] then
          serviceCfg.command
        else
          "${serviceCfg.command} ${concatStringsSep " " serviceCfg.args}";

      # Environment setup
      envSetup = concatStringsSep "\n" (
        mapAttrsToList (k: v: "export ${k}=\"${v}\"") (serviceCfg.environment or { })
      );

      # PATH setup
      pathPackages = serviceCfg.path or [ ];
      pathSetup = optionalString (pathPackages != [ ]) ''
        export PATH="${makeBinPath pathPackages}:$PATH"
      '';

      # User/group switching
      userGroup =
        if (serviceCfg.user or null) != null then
          (
            if (serviceCfg.group or null) != null then
              "${serviceCfg.user}:${serviceCfg.group}"
            else
              serviceCfg.user
          )
        else
          null;

      chpstCmd = optionalString (userGroup != null) "${pkgs.runit}/bin/chpst -u ${userGroup} ";

      # Working directory
      cdCmd = optionalString (
        (serviceCfg.workingDirectory or null) != null
      ) "cd ${serviceCfg.workingDirectory}";

      # Runit-specific options
      runitCfg = serviceCfg.runit or { };

      # Run script
      runScript = pkgs.writeScript "${name}-run" ''
        #!/bin/sh
        # ${serviceCfg.description or name}

        ${envSetup}
        ${pathSetup}
        ${cdCmd}

        # PreStart hook
        ${serviceCfg.preStart or ""}

        # Extra run script content
        ${runitCfg.extraRunScript or ""}

        # Execute service
        exec ${chpstCmd}${execCommand}
      '';

      # Finish script (for postStop hook)
      finishScript =
        if (serviceCfg.postStop or "") != "" || (runitCfg.extraFinishScript or "") != "" then
          pkgs.writeScript "${name}-finish" ''
            #!/bin/sh
            # Finish script for ${name}
            # Arguments: $1 = exit code, $2 = exit signal (if killed by signal)

            ${serviceCfg.postStop or ""}
            ${runitCfg.extraFinishScript or ""}
          ''
        else
          null;

      # Log script (optional)
      logScript =
        if (runitCfg.logScript or null) != null then
          pkgs.writeScript "${name}-log" runitCfg.logScript
        else
          null;

    in
    pkgs.runCommand "${name}-runit-service" { } ''
      mkdir -p $out

      # Create run script
      cp ${runScript} $out/run
      chmod +x $out/run

      # Create finish script if needed
      ${optionalString (finishScript != null) ''
        cp ${finishScript} $out/finish
        chmod +x $out/finish
      ''}

      # Create log directory and script if needed
      ${optionalString (logScript != null) ''
        mkdir -p $out/log
        cp ${logScript} $out/log/run
        chmod +x $out/log/run
      ''}

      # Create check script if defined
      ${optionalString ((runitCfg.extraConfig.checkScript or "") != "") ''
                cat > $out/check <<'EOF'
        #!/bin/sh
        ${runitCfg.extraConfig.checkScript}
        EOF
                chmod +x $out/check
      ''}
    '';

  # Generate all runit services
  runitServices = mapAttrs mkRunitService enabledServices;

in

{
  options.serviceManager.runit = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable runit as the service manager";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.runit;
      description = "The runit package to use.";
    };

    serviceDir = mkOption {
      type = types.str;
      default = "/service";
      description = "The runit service directory where services are supervised from.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Mutual exclusion assertions
    {
      assertions = [
        {
          assertion = !(config.serviceManager.systemd.enable or false);
          message = "Cannot enable both runit and systemd service managers. Only one service manager can be enabled at a time.";
        }
        {
          assertion = !(config.serviceManager.launchd.enable or false);
          message = "Cannot enable both runit and launchd service managers. Only one service manager can be enabled at a time.";
        }
        {
          assertion = !(config.serviceManager.rcd.enable or false);
          message = "Cannot enable both runit and rcd service managers. Only one service manager can be enabled at a time.";
        }
      ];
    }

    # Runit configuration
    {
      # Install runit service directories to /etc/sv/
      environment.etc = mkMerge [
        (listToAttrs (
          map (
            name:
            nameValuePair "sv/${name}" {
              source = runitServices.${name};
            }
          ) (attrNames runitServices)
        ))
      ];

      # TODO: Modify stage-2 init to use runsvdir instead of systemd
      # This would require changes to boot/stage-2.nix to check which
      # service manager is enabled and exec the appropriate init system

      # For now, we just install the service directories
      # A complete implementation would need:
      # 1. boot.init.command = "${cfg.package}/bin/runsvdir ${cfg.serviceDir}";
      # 2. Symlinks from /etc/sv/* to ${cfg.serviceDir}/*
      # 3. Proper runit stage-1/stage-2/stage-3 scripts
    }
  ]);
}
