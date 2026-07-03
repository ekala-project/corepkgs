# Cross-platform scheduled tasks
# Defines timers.* options consumed by service manager modules
# Replaces the systemd-specific systemd.timers module
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  timerOpts = import ../../../services/lib/timer-options.nix { inherit lib; };
  timerModule = import ../../../services/lib/timer-module.nix { inherit lib pkgs; };

  enabledTimers = filterAttrs (_: t: t.enable) config.timers;

  timerSubmodule =
    { name, ... }:
    {
      options = timerOpts.commonTimerOptions // {
        name = mkOption {
          type = types.str;
          default = name;
          internal = true;
        };

        # Platform-specific overrides
        systemd = mkOption {
          type = types.attrsOf types.anything;
          default = { };
          description = "Systemd-specific timer overrides.";
        };

        launchd = mkOption {
          type = types.attrsOf types.anything;
          default = { };
          description = "Launchd-specific timer overrides.";
        };

        runit = mkOption {
          type = types.attrsOf types.anything;
          default = { };
          description = "Runit-specific timer overrides.";
        };

        rcd = mkOption {
          type = types.attrsOf types.anything;
          default = { };
          description = "BSD rc.d-specific timer overrides.";
        };
      };
    };

in

{
  options.timers = mkOption {
    type = types.attrsOf (types.submodule timerSubmodule);
    default = { };
    example = literalExpression ''
      {
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
      }
    '';
    description = ''
      Cross-platform scheduled task definitions.
      Automatically translated to the appropriate format for the
      active service manager (systemd timers, launchd scheduling,
      runit sleep loops, or cron entries).
    '';
  };

  # The service manager modules (systemd.nix, runit.nix, etc.)
  # consume config.timers and generate platform-specific output.
  # This module only defines the options.

  config = mkIf (enabledTimers != { }) {
    # For systemd: generate timer + service unit files
    # This is done here for now since the systemd service manager module
    # doesn't yet consume timers. Future: move to service-managers/systemd.nix.
    environment.etc = mkIf (config.serviceManager.systemd.enable or false) (mkMerge [
      (listToAttrs (
        mapAttrsToList (
          name: timerCfg:
          nameValuePair "systemd/system/${name}.timer" {
            text = timerModule.systemdTranslate.toTimerUnit name timerCfg;
          }
        ) enabledTimers
      ))

      (listToAttrs (
        mapAttrsToList (
          name: timerCfg:
          nameValuePair "systemd/system/${name}.service" {
            text = timerModule.systemdTranslate.toServiceUnit name timerCfg;
          }
        ) enabledTimers
      ))
    ]);
  };
}
