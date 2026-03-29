# Translate common service options to systemd unit files
{ lib, pkgs }:

let
  inherit (lib)
    concatStringsSep
    concatMapStringsSep
    optionalString
    mapAttrsToList
    filterAttrs
    escapeShellArg
    ;

  # Generate environment directives
  mkEnvironment =
    env:
    concatStringsSep "\n" (
      mapAttrsToList (
        name: value:
        let
          val =
            if lib.isDerivation value then
              value
            else if lib.isPath value then
              toString value
            else
              value;
        in
        "Environment=${escapeShellArg "${name}=${toString val}"}"
      ) env
    );

  # Generate PATH from package list
  mkPath =
    packages:
    let
      paths = map (pkg: "${pkg}/bin:${pkg}/sbin") packages;
    in
    if paths != [ ] then "Environment=\"PATH=${concatStringsSep ":" paths}\"" else "";

  # Convert restart policy to systemd format
  mkRestart =
    policy:
    {
      always = "always";
      on-failure = "on-failure";
      on-abnormal = "on-abnormal";
      on-abort = "on-abort";
      on-watchdog = "on-watchdog";
      never = "no";
    }
    .${policy};

  # Generate ExecStart line
  mkExecStart =
    { command, args, ... }:
    let
      cmd = toString command;
      argStr = if args != [ ] then " " + concatStringsSep " " (map escapeShellArg args) else "";
    in
    "ExecStart=${cmd}${argStr}";

  # Generate a script wrapper for multi-line commands
  mkScript =
    name: text: user:
    pkgs.writeScript "${name}-script" ''
      #!${pkgs.bash}/bin/bash
      set -e
      ${text}
    '';

  # Generate [Unit] section
  mkUnitSection =
    config:
    let
      cfg = config.systemd or { };
      deps = concatStringsSep "\n" (
        (map (d: "Wants=${d}") cfg.wants)
        ++ (map (d: "Requires=${d}") cfg.requires)
        ++ (map (d: "After=${d}") cfg.after)
        ++ (map (d: "Before=${d}") cfg.before)
      );
      unitConfig = concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${toString v}") cfg.unitConfig);
    in
    ''
      [Unit]
      Description=${config.description}
      ${deps}
      ${unitConfig}
    '';

  # Generate [Service] section
  mkServiceSection =
    config:
    let
      cfg = config.systemd or { };
      preStartScript = optionalString (config.preStart != "") (
        let
          script = mkScript "${config.description}-prestart" config.preStart config.user;
        in
        "ExecStartPre=${script}"
      );
      postStartScript = optionalString (config.postStart != "") (
        let
          script = mkScript "${config.description}-poststart" config.postStart config.user;
        in
        "ExecStartPost=${script}"
      );
      postStopScript = optionalString (config.postStop != "") (
        let
          script = mkScript "${config.description}-poststop" config.postStop config.user;
        in
        "ExecStopPost=${script}"
      );
      serviceConfig = concatStringsSep "\n" (
        mapAttrsToList (k: v: "${k}=${toString v}") cfg.serviceConfig
      );
    in
    ''
      [Service]
      Type=simple
      ${mkExecStart config}
      Restart=${mkRestart config.restartPolicy}
      ${optionalString (config.user != "root") "User=${config.user}"}
      ${optionalString (config.group != "root") "Group=${config.group}"}
      ${optionalString (
        config.workingDirectory != null
      ) "WorkingDirectory=${toString config.workingDirectory}"}
      ${mkEnvironment config.environment}
      ${mkPath config.path}
      ${preStartScript}
      ${postStartScript}
      ${postStopScript}
      ${serviceConfig}
    '';

  # Generate [Install] section
  mkInstallSection =
    { serviceType ? "user" }:
    config:
    let
      cfg = config.systemd or { };
      # Auto-adjust wantedBy for system services:
      # If it's still the default user target and we're building a system service,
      # use multi-user.target instead
      adjustedWantedBy =
        if serviceType == "system" && cfg.wantedBy == [ "default.target" ] then
          [ "multi-user.target" ]
        else
          cfg.wantedBy;
      wantedBy = concatMapStringsSep "\n" (t: "WantedBy=${t}") adjustedWantedBy;
    in
    ''
      [Install]
      ${wantedBy}
    '';

in
{
  # Main translation function
  # opts: { serviceType = "user" | "system" }
  toSystemdUnit =
    { serviceType ? "user" }:
    config: ''
      ${mkUnitSection config}

      ${mkServiceSection config}

      ${mkInstallSection { inherit serviceType; } config}
    '';
}
