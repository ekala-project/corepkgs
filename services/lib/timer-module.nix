# Timer module infrastructure — parallel to service-module.nix
# Provides unified timer definitions across service managers
{ lib, pkgs }:

let
  inherit (lib)
    types
    mkOption
    mapAttrs
    filterAttrs
    ;

  timerOpts = import ./timer-options.nix { inherit lib; };
  systemdTranslate = import ./timer-systemd-translate.nix { inherit lib pkgs; };
  launchdTranslate = import ./timer-launchd-translate.nix { inherit lib pkgs; };
  runitTranslate = import ./timer-runit-translate.nix { inherit lib pkgs; };
  rcdTranslate = import ./timer-rcd-translate.nix { inherit lib pkgs; };

  # Timer option type
  timerSubmodule =
    { name, config, ... }:
    {
      options = timerOpts.commonTimerOptions // {
        name = mkOption {
          type = types.str;
          default = name;
          description = "Timer name.";
        };
      };
    };

in
{
  # Create a timers.* module option
  mkTimersOption = mkOption {
    default = { };
    type = types.attrsOf (types.submodule timerSubmodule);
    description = "Attribute set of scheduled tasks.";
  };

  # Generate systemd timer + service unit files
  mkSystemdTimers =
    timers:
    let
      enabled = filterAttrs (_: t: t.enable) timers;
    in
    mapAttrs (
      name: config:
      {
        timer = pkgs.writeTextFile {
          name = "${name}.timer";
          text = systemdTranslate.toTimerUnit name config;
          destination = "/${name}.timer";
        };
        service = pkgs.writeTextFile {
          name = "${name}.service";
          text = systemdTranslate.toServiceUnit name config;
          destination = "/${name}.service";
        };
      }
    ) enabled;

  # Generate launchd plist files with scheduling
  mkLaunchdTimerAgents =
    timers:
    let
      enabled = filterAttrs (_: t: t.enable) timers;
    in
    mapAttrs (
      name: config:
      pkgs.writeTextFile {
        name = "${name}.plist";
        text = launchdTranslate.toLaunchdPlist name config;
        destination = "/${name}.plist";
      }
    ) enabled;

  # Generate runit service dirs for interval timers, crontab lines for calendar
  mkRunitTimers =
    timers:
    let
      enabled = filterAttrs (_: t: t.enable) timers;
      intervalTimers = filterAttrs (_: t: t.schedule.interval != null) enabled;
      calendarTimers = filterAttrs (_: t: t.schedule.calendar != null && t.schedule.interval == null) enabled;
    in
    {
      # Interval-based: runit service directories with sleep loops
      services = mapAttrs (name: config: runitTranslate.toRunitIntervalService name config) intervalTimers;

      # Calendar-based: crontab entries
      crontab = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: config: runitTranslate.toCrontabEntry name config) calendarTimers
      );
    };

  # Generate BSD crontab entries or periodic scripts
  mkRcdTimers =
    timers:
    let
      enabled = filterAttrs (_: t: t.enable) timers;
    in
    {
      crontab = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: config: rcdTranslate.toCrontabEntry name config) enabled
      );
    };

  inherit systemdTranslate launchdTranslate runitTranslate rcdTranslate;
}
