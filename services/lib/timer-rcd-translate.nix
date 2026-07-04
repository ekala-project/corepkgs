# Translate common timer options to BSD crontab entries or periodic scripts
{ lib, pkgs }:

let
  inherit (lib) optionalString concatStringsSep mapAttrsToList;

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
      "0 0 * * *";

  mkEnvExports = env: concatStringsSep "\n" (mapAttrsToList (k: v: "export ${k}=\"${v}\"") env);

  mkPathExport =
    path:
    optionalString (path != [ ])
      "export PATH=\"${concatStringsSep ":" (map (p: "${p}/bin") path)}:$PATH\"";

in
{
  # Generate a crontab entry
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

  # Generate a BSD periodic(8) script (FreeBSD-style)
  toPeriodicScript =
    name: config:
    let
      period =
        if config.schedule.calendar == "daily" then
          "daily"
        else if config.schedule.calendar == "weekly" then
          "weekly"
        else if config.schedule.calendar == "monthly" then
          "monthly"
        else
          "daily";
    in
    {
      inherit period;
      script = pkgs.writeShellScript "${name}-periodic" ''
        #!/bin/sh
        # ${config.description}
        ${mkEnvExports config.environment}
        ${mkPathExport config.path}
        ${optionalString (config.user != "root") "su -m ${config.user} -c '"}
        ${config.script}
        ${optionalString (config.user != "root") "'"}
      '';
    };
}
