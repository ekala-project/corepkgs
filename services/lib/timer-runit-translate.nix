# Translate common timer options to runit service directories
# For interval-based: run script with sleep loop
# For calendar-based: generate crontab entry
{ lib, pkgs }:

let
  inherit (lib)
    optionalString
    concatStringsSep
    concatMapStringsSep
    mapAttrsToList
    ;

  # Convert calendar shorthand to cron expression
  calendarToCron =
    cal:
    if cal == "minutely" then
      "* * * * *"
    else if cal == "hourly" then
      "0 * * * *"
    else if cal == "daily" then
      "0 0 * * *"
    else if cal == "weekly" then
      "0 0 * * 0"
    else if cal == "monthly" then
      "0 0 1 * *"
    else
      # Best-effort: treat as daily for unknown expressions
      "0 0 * * *";

  mkEnvExports = env: concatStringsSep "\n" (mapAttrsToList (k: v: "export ${k}=\"${v}\"") env);

  mkPathExport =
    path:
    optionalString (path != [ ])
      "export PATH=\"${concatStringsSep ":" (map (p: "${p}/bin") path)}:$PATH\"";

in
{
  # Generate a runit service directory for interval-based timers
  toRunitIntervalService =
    name: config:
    let
      sched = config.schedule;
      interval = if sched.interval != null then sched.interval else 3600;
    in
    pkgs.runCommand "timer-${name}" { } ''
      mkdir -p $out/run $out/log

      cat > $out/run/run <<'SCRIPT'
      #!/bin/sh
      exec 2>&1
      ${mkEnvExports config.environment}
      ${mkPathExport config.path}
      while true; do
        echo "[timer:${name}] Running at $(date)"
        ${optionalString (config.user != "root") "exec chpst -u ${config.user}:${config.group}"} \
        ${pkgs.writeShellScript "${name}-timer" config.script} || true
        sleep ${toString interval}
      done
      SCRIPT
      chmod +x $out/run/run

      cat > $out/log/run <<'LOG'
      #!/bin/sh
      exec svlogd -tt $out/log/
      LOG
      chmod +x $out/log/run
    '';

  # Generate a crontab line for calendar-based timers
  toCrontabEntry =
    name: config:
    let
      sched = config.schedule;
      cronExpr = calendarToCron sched.calendar;
      scriptDrv = pkgs.writeShellScript "${name}-timer" ''
        ${mkEnvExports config.environment}
        ${mkPathExport config.path}
        ${config.script}
      '';
    in
    "${cronExpr} ${config.user} ${scriptDrv}";
}
