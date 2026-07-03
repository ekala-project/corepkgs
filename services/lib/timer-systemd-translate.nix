# Translate common timer options to systemd .timer + .service units
{ lib, pkgs }:

let
  inherit (lib)
    optionalString
    concatStringsSep
    concatMapStringsSep
    mapAttrsToList
    ;
in
{
  # Generate systemd .timer unit content
  toTimerUnit =
    name: config:
    let
      sched = config.schedule;
    in
    ''
      [Unit]
      Description=Timer for ${config.description}

      [Timer]
      ${optionalString (sched.calendar != null) "OnCalendar=${sched.calendar}"}
      ${optionalString (sched.interval != null) "OnUnitActiveSec=${toString sched.interval}s"}
      ${optionalString (sched.onBoot != null) "OnBootSec=${sched.onBoot}"}
      ${optionalString sched.persistent "Persistent=true"}
      ${optionalString (sched.randomDelay != null) "RandomizedDelaySec=${toString sched.randomDelay}s"}
      Unit=${name}.service

      [Install]
      WantedBy=timers.target
    '';

  # Generate systemd oneshot .service unit content
  toServiceUnit =
    name: config:
    let
      envVars = mapAttrsToList (k: v: "Environment=\"${k}=${v}\"") config.environment;
      pathDirs = map (p: "${p}/bin") config.path;
      scriptDrv = pkgs.writeShellScript "${name}-timer" config.script;
    in
    ''
      [Unit]
      Description=${config.description}

      [Service]
      Type=oneshot
      ExecStart=${scriptDrv}
      User=${config.user}
      Group=${config.group}
      ${optionalString (pathDirs != []) "Environment=\"PATH=${concatStringsSep ":" pathDirs}:/run/current-system/sw/bin\""}
      ${concatStringsSep "\n" envVars}
    '';
}
