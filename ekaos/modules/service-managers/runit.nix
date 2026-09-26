# Adios port of ekaos/modules/service-managers/runit.nix.
#
# Tree path: service-managers/runit is parent.runit.
# Consumes service definitions and generates runit service directories
# under /etc/sv/ (system) and /etc/sv-user/ (user). Derivation builders
# close over pkgs in the top-level let (impl only sees
# { options, inputs }).
# TODO(adios-cutover): AGGREGATION GAP (load-bearing). Legacy filters
# enabled services out of ALL of config.services / config.users.services
# via the global fixpoint. Adios inputs resolve to whatever the tree
# wires at parent.services / parent.config."user-services"; arbitrary
# service modules outside the tree are invisible and their units are
# silently missing.
# TODO(adios-cutover): mutual-exclusion assertions are guarded by
# `!options.enable || ...` (legacy evaluated them only when enabled).
# TODO(adios-cutover): makeBinPath has no adios.lib equivalent; smallest
# local reimplementation below.
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
  makeBinPath = packages: builtins.concatStringsSep ":" (builtins.map (p: "${p}/bin") packages);

  # Generate a runit service directory for a service
  mkRunitService =
    name: serviceCfg:
    let
      # Build command with args
      execCommand =
        if (serviceCfg.args or [ ]) == [ ] then
          serviceCfg.command
        else
          "${serviceCfg.command} ${builtins.concatStringsSep " " serviceCfg.args}";

      # Environment setup
      envSetup = builtins.concatStringsSep "\n" (
        mapAttrsToList (k: v: "export ${k}=\"${v}\"") (serviceCfg.environment or { })
      );

      # PATH setup
      pathPackages = serviceCfg.path or [ ];
      pathSetup =
        if pathPackages != [ ] then
          ''
            export PATH="${makeBinPath pathPackages}:$PATH"
          ''
        else
          "";

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

      chpstCmd = if userGroup != null then "${pkgs.runit}/bin/chpst -u ${userGroup} " else "";

      # Working directory
      cdCmd =
        if ((serviceCfg.workingDirectory or null) != null) then "cd ${serviceCfg.workingDirectory}" else "";

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
      ${
        if finishScript != null then
          ''
            cp ${finishScript} $out/finish
            chmod +x $out/finish
          ''
        else
          ""
      }

      # Create log directory and script if needed
      ${
        if logScript != null then
          ''
            mkdir -p $out/log
            cp ${logScript} $out/log/run
            chmod +x $out/log/run
          ''
        else
          ""
      }

      # Create check script if defined
      ${
        if ((runitCfg.extraConfig.checkScript or "") != "") then
          ''
                      cat > $out/check <<'EOF'
            #!/bin/sh
            ${runitCfg.extraConfig.checkScript}
            EOF
                    chmod +x $out/check
          ''
        else
          ""
      }
    '';

  # Generate a runit user service directory
  mkRunitUserService =
    name: serviceCfg:
    let
      execCommand =
        if serviceCfg.args == [ ] then
          serviceCfg.command
        else
          "${serviceCfg.command} ${builtins.concatStringsSep " " serviceCfg.args}";

      envSetup = builtins.concatStringsSep "\n" (
        mapAttrsToList (k: v: "export ${k}=\"${v}\"") serviceCfg.environment
      );

      cdCmd = if serviceCfg.workingDirectory != null then "cd ${serviceCfg.workingDirectory}" else "";

      runitCfg = serviceCfg.runit;

      runScript = pkgs.writeScript "${name}-run" ''
        #!/bin/sh
        # ${serviceCfg.description}

        ${envSetup}
        ${cdCmd}

        # PreStart hook
        ${serviceCfg.preStart}

        # Extra run script content
        ${runitCfg.extraRunScript or ""}

        # Execute service (no chpst - runs as the logged-in user)
        exec ${execCommand}
      '';

      finishScript =
        if serviceCfg.postStop != "" || (runitCfg.extraFinishScript or "") != "" then
          pkgs.writeScript "${name}-finish" ''
            #!/bin/sh
            # Finish script for ${name}
            ${serviceCfg.postStop}
            ${runitCfg.extraFinishScript or ""}
          ''
        else
          null;

      logScript =
        if (runitCfg.logScript or null) != null then
          pkgs.writeScript "${name}-log" runitCfg.logScript
        else
          null;

    in
    pkgs.runCommand "${name}-runit-user-service" { } ''
      mkdir -p $out

      cp ${runScript} $out/run
      chmod +x $out/run

      ${
        if finishScript != null then
          ''
            cp ${finishScript} $out/finish
            chmod +x $out/finish
          ''
        else
          ""
      }

      ${
        if logScript != null then
          ''
            mkdir -p $out/log
            cp ${logScript} $out/log/run
            chmod +x $out/log/run
          ''
        else
          ""
      }
    '';
in

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Enable runit as the service manager";
    };

    package = {
      type = types.derivation;
      default = pkgs.runit;
      description = "The runit package to use.";
    };

    serviceDir = {
      type = types.string;
      default = "/service";
      description = "The runit service directory where services are supervised from.";
    };
  };

  inputs = {
    services.from = { root }: root.services;
    userServices.from = { root }: root.config."user-services";
    systemdMgr.from = { parent }: parent.systemd;
    launchdMgr.from = { parent }: parent.launchd;
    rcdMgr.from = { parent }: parent.rcd;
  };

  assertions = [
    {
      verify = { options, inputs }: !options.enable || !(inputs.systemdMgr.enable or false);
      explain =
        { options, inputs }:
        "Cannot enable both runit and systemd service managers. Only one service manager can be enabled at a time.";
    }
    {
      verify = { options, inputs }: !options.enable || !(inputs.launchdMgr.enable or false);
      explain =
        { options, inputs }:
        "Cannot enable both runit and launchd service managers. Only one service manager can be enabled at a time.";
    }
    {
      verify = { options, inputs }: !options.enable || !(inputs.rcdMgr.enable or false);
      explain =
        { options, inputs }:
        "Cannot enable both runit and rcd service managers. Only one service manager can be enabled at a time.";
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

      # Generate all runit services
      runitServices = builtins.mapAttrs mkRunitService enabledServices;

      # Generate all runit user services
      runitUserServices = builtins.mapAttrs mkRunitUserService enabledUserServices;
    in
    if !options.enable then
      { }
    else
      {
        # Install runit service directories to /etc/sv/
        environment.etc =
          # Install system runit service directories to /etc/sv/
          builtins.listToAttrs (
            builtins.map (name: {
              name = "sv/${name}";
              value = {
                source = runitServices.${name};
              };
            }) (builtins.attrNames runitServices)
          )
          // builtins.listToAttrs (
            builtins.map (name: {
              name = "sv-user/${name}";
              value = {
                source = runitUserServices.${name};
              };
            }) (builtins.attrNames runitUserServices)
          );

        # TODO: Modify stage-2 init to use runsvdir instead of systemd
        # This would require changes to boot/stage-2.nix to check which
        # service manager is enabled and exec the appropriate init system

        # For now, we just install the service directories
        # A complete implementation would need:
        # 1. boot.init.command = "${options.package}/bin/runsvdir ${options.serviceDir}";
        # 2. Symlinks from /etc/sv/* to ${options.serviceDir}/*
        # 3. Proper runit stage-1/stage-2/stage-3 scripts
      };
}
