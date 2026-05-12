# Translate common service options to runit service directory
{ lib, pkgs }:

let
  inherit (lib)
    concatStringsSep
    concatMapStringsSep
    optionalString
    mapAttrsToList
    escapeShellArg
    ;

  # Generate environment variable exports for shell script
  mkEnvironmentExports =
    env:
    concatStringsSep "\n" (
      mapAttrsToList (
        name: value:
        let
          val =
            if lib.isPath value then
              toString value
            else
              value;
        in
        "export ${name}=${escapeShellArg (toString val)}"
      ) env
    );

  # Generate PATH from package list
  mkPathExport =
    packages:
    if packages != [ ] then "export PATH=${lib.makeBinPath packages}:$PATH" else "";

  # Generate command line with args
  mkCommandLine =
    { command, args, ... }:
    let
      cmd = toString command;
      argStr = if args != [ ] then " " + concatStringsSep " " (map escapeShellArg args) else "";
    in
    "${cmd}${argStr}";

  # Generate user/group switching using chpst
  mkUserSwitch =
    config:
    let
      user = config.user or "root";
      group = config.group or "root";
    in
    if user != "root" then
      let
        userSpec = if group != "root" then "${user}:${group}" else user;
      in
      "exec chpst -u ${userSpec} \\\n  "
    else
      "exec ";

  # Generate the run script
  mkRunScript =
    name: config:
    let
      cfg = config.runit or { };

      # Working directory change
      workingDirCmd = optionalString ((config.workingDirectory or null) != null) ''
        cd ${escapeShellArg (toString config.workingDirectory)}
      '';

      # Environment setup
      envExports =
        if (config.environment or { }) != { } then mkEnvironmentExports config.environment else "";

      # PATH setup
      pathExport = mkPathExport (config.path or [ ]);

      # preStart hook
      preStartCmd = optionalString ((config.preStart or "") != "") ''
        # preStart hook
        ${config.preStart}
      '';

      # Extra run script content
      extraRun = optionalString ((cfg.extraRunScript or "") != "") cfg.extraRunScript;

      # User switching and exec
      userExec = mkUserSwitch config;
      commandLine = mkCommandLine config;

    in
    pkgs.writeScript "${name}-run" ''
      #!/bin/sh
      set -e

      ${optionalString (envExports != "") envExports}
      ${optionalString (pathExport != "") pathExport}
      ${optionalString (preStartCmd != "") preStartCmd}
      ${optionalString (workingDirCmd != "") workingDirCmd}
      ${optionalString (extraRun != "") extraRun}

      ${userExec}${commandLine}
    '';

  # Generate the finish script (for postStop)
  mkFinishScript =
    name: config:
    let
      cfg = config.runit or { };
      postStop = config.postStop or ":";
      extraFinish = cfg.extraFinishScript or ":";
    in
      pkgs.writeScript "${name}-finish" ''
        #!/bin/sh
        # Arguments: $1 = exit code, $2 = signal number

        # postStop hook
        ${postStop}

        ${extraFinish}
      '';

  # Generate optional check script
  mkCheckScript =
    name: config:
    let
      cfg = config.runit or { };
      extraConfig = cfg.extraConfig or { };
      checkScriptContent = extraConfig.checkScript or null;
    in
    if checkScriptContent != null then pkgs.writeScript "${name}-check" checkScriptContent else null;

  # Generate optional log/run script
  mkLogScript =
    name: config:
    let
      cfg = config.runit or { };
      logScript = cfg.logScript or null;
    in
    if logScript != null then pkgs.writeScript "${name}-log-run" logScript else null;

  # Build the complete service directory
  mkServiceDirectory =
    name: config:
    let
      runScript = mkRunScript name config;
      finishScript = mkFinishScript name config;
      checkScript = mkCheckScript name config;
      logScript = mkLogScript name config;
    in
    pkgs.runCommand "${name}-runit-service" { } ''
      mkdir -p $out

      # Install run script (required)
      cp ${runScript} $out/run
      chmod +x $out/run

      # Install finish script if present
      ${optionalString (finishScript != null) ''
        cp ${finishScript} $out/finish
        chmod +x $out/finish
      ''}

      # Install check script if present
      ${optionalString (checkScript != null) ''
        cp ${checkScript} $out/check
        chmod +x $out/check
      ''}

      # Install log/run script if present
      ${optionalString (logScript != null) ''
        mkdir -p $out/log
        cp ${logScript} $out/log/run
        chmod +x $out/log/run
      ''}
    '';

in
{
  # Main translation function
  toRunitService = name: config: mkServiceDirectory name config;
}
