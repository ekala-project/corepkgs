# Adios port of ekaos/modules/tasks/timers.nix.
#
# Tree path: tasks/timers is parent.tasks.timers.
#
# Cross-platform scheduled tasks: defines timers.* options consumed by the
# service-manager modules. When the systemd manager is enabled
# (inputs.systemdMgr, parent.service-managers.systemd), timer + service
# unit files are generated via the shared translate helper.
#
# TODO(adios-cutover): HELPER GAP (load-bearing). services/lib/
# timer-options.nix and timer-module.nix are nixpkgs-lib-based
# (`{ lib }:` / `{ lib, pkgs }:`) and need adios-aware rewrites owned
# outside this batch. The imports below keep their legacy call shape with
# adjusted relative paths; `lib` here is adios.lib, so evaluation fails
# until the helpers are rewritten. Timers option shape (from
# commonTimerOptions): enable, description, script, user (default root),
# group (default root), environment, path, schedule.{calendar,interval,
# onBoot,persistent,randomDelay}, plus systemd/launchd/runit/rcd
# platform-override attrs.
# TODO(adios-cutover): timers is types.attrsOf types.attrs; per-timer
# field validation lost.
{
  types,
  lib,
  pkgs,
  ...
}:

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

  timerOpts = import ../../../../services/lib/timer-options.nix { inherit lib; };
  timerModule = import ../../../../services/lib/timer-module.nix { inherit lib pkgs; };
  _commonOptions = timerOpts.commonTimerOptions;
in

{
  options = {
    timers = {
      type = types.attrsOf types.attrs;
      default = { };
      example = {
        nix-gc = {
          description = "Nix garbage collection";
          schedule.calendar = "weekly";
          schedule.persistent = true;
          script = "nix-collect-garbage --delete-older-than 30d";
        };
        log-cleanup = {
          description = "Clean old logs";
          schedule.calendar = "daily";
          script = "find /var/log -name '*.gz' -mtime +30 -delete";
        };
        health-check = {
          description = "Periodic health check";
          schedule.interval = 300;
          script = "curl -sf http://localhost:8080/health || echo UNHEALTHY";
        };
      };
      description = ''
        Cross-platform scheduled task definitions.
        Automatically translated to the appropriate format for the
        active service manager (systemd timers, launchd scheduling,
        runit sleep loops, or cron entries).
      '';
    };
  };

  inputs = {
    systemdMgr.from = { root }: root."service-managers".systemd;
  };

  impl =
    { options, inputs }:
    let
      enabledTimers = filterAttrs (_: t: (t.enable or false)) options.timers;
    in
    # The service manager modules (systemd.nix, runit.nix, etc.)
    # consume timers and generate platform-specific output.
    # For systemd: generate timer + service unit files here for now since
    # the systemd service manager module doesn't yet consume timers.
    # Future: move to service-managers/systemd.nix.
    if enabledTimers == { } then
      { }
    else if !(inputs.systemdMgr.enable or false) then
      { }
    else
      {
        environment.etc =
          builtins.listToAttrs (
            mapAttrsToList (name: timerCfg: {
              name = "systemd/system/${name}.timer";
              value = {
                text = timerModule.systemdTranslate.toTimerUnit name timerCfg;
              };
            }) enabledTimers
          )
          // builtins.listToAttrs (
            mapAttrsToList (name: timerCfg: {
              name = "systemd/system/${name}.service";
              value = {
                text = timerModule.systemdTranslate.toServiceUnit name timerCfg;
              };
            }) enabledTimers
          );
      };
}
