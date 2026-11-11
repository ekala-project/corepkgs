# Unit-file keys read by the ekaos switch engine
#
# These are the same keys, in the same sections, that nixpkgs'
# switch-to-configuration-ng reads, so the engine can share its unit
# classification logic:
#
#   [Unit]     X-Restart-Triggers, X-Reload-Triggers, X-StopOnRemoval,
#              X-OnlyManualStart, X-StopOnReconfiguration
#   [Service]  X-ReloadIfChanged, X-RestartIfChanged, X-StopIfChanged,
#              X-NotSocketActivated
#
# Keys are only written when they differ from the engine's default, so
# unit files without them keep the default behaviour (restart on change,
# stop on removal).
#
# `cfg` is a plain attrset; every field is optional:
#   restartIfChanged ? true, reloadIfChanged ? false, stopIfChanged ? true,
#   notSocketActivated ? false, stopOnRemoval ? true, onlyManualStart ? false,
#   stopOnReconfiguration ? false, restartTriggers ? [ ], reloadTriggers ? [ ]
{ lib, pkgs }:

let
  inherit (lib)
    flatten
    isPath
    optional
    pipe
    concatStringsSep
    ;

  triggersFile =
    kind: name: triggers:
    pkgs.writeText "X-${kind}-Triggers-${name}" (
      pipe triggers [
        flatten
        (map (x: if isPath x then "${x}" else toString x))
        toString
      ]
    );
in
{
  # Lines for the [Unit] section.
  unitLines =
    name: cfg:
    let
      restartTriggers = cfg.restartTriggers or [ ];
      reloadTriggers = cfg.reloadTriggers or [ ];
    in
    concatStringsSep "\n" (
      optional (restartTriggers != [ ])
        "X-Restart-Triggers=${triggersFile "Restart" name restartTriggers}"
      ++ optional (reloadTriggers != [ ]) "X-Reload-Triggers=${triggersFile "Reload" name reloadTriggers}"
      ++ optional (!(cfg.stopOnRemoval or true)) "X-StopOnRemoval=false"
      ++ optional (cfg.onlyManualStart or false) "X-OnlyManualStart=true"
      ++ optional (cfg.stopOnReconfiguration or false) "X-StopOnReconfiguration=true"
    );

  # Lines for the [Service] section. As in NixOS, reloadIfChanged takes
  # precedence over restartIfChanged = false.
  serviceLines =
    cfg:
    concatStringsSep "\n" (
      (
        if cfg.reloadIfChanged or false then
          [ "X-ReloadIfChanged=true" ]
        else
          optional (!(cfg.restartIfChanged or true)) "X-RestartIfChanged=false"
      )
      ++ optional (!(cfg.stopIfChanged or true)) "X-StopIfChanged=false"
      ++ optional (cfg.notSocketActivated or false) "X-NotSocketActivated=true"
    );
}
