# Adios port of ekaos/modules/system/logind.nix.
#
# Tree path: system/logind is parent.system.logind.
# Self-contained; no cross-module reads. logind.conf generation is pure
# (no derivations), so the header takes only types.
# TODO(adios-cutover): priority lost (was mkDefault): the KillUserProcesses
# / HandlePowerKey / HandleLidSwitch / IdleAction defaults no longer yield
# to user overrides at merge time; user settings win via `//` below.
# TODO(adios-cutover): impl returns services.logind.settings (this
# module's own option); the tree must merge impl outputs back (NixOS
# module-merge semantics).
{ types, ... }:

let
  mapAttrsToList = f: attrs: builtins.map (n: f n attrs.${n}) (builtins.attrNames attrs);
in

{
  options = {
    enable = {
      type = types.bool;
      default = true;
      description = "Whether to enable systemd-logind session management.";
    };

    settings = {
      type = types.attrsOf (
        types.union [
          types.bool
          types.int
          types.string
        ]
      );
      default = { };
      example = {
        HandlePowerKey = "poweroff";
        HandleLidSwitch = "suspend";
        KillUserProcesses = false;
        IdleAction = "ignore";
      };
      description = ''
        Settings for systemd-logind. See logind.conf(5).

        Common settings:
          HandlePowerKey — Action on power button (poweroff, reboot, suspend, hibernate, ignore)
          HandleLidSwitch — Action on lid close
          HandleLidSwitchExternalPower — Action on lid close when on AC power
          HandleLidSwitchDocked — Action on lid close when docked
          KillUserProcesses — Kill user processes on logout (default: no)
          IdleAction — Action when system is idle (ignore, poweroff, suspend, etc.)
          IdleActionSec — Seconds of idle before IdleAction triggers
          InhibitDelayMaxSec — Max seconds to delay for inhibitors
      '';
    };
  };

  impl =
    { options, inputs }:
    let
      effectiveSettings = {
        KillUserProcesses = false;
        HandlePowerKey = "poweroff";
        HandleLidSwitch = "suspend";
        IdleAction = "ignore";
      }
      // options.settings;

      formatValue = v: if builtins.isBool v then (if v then "yes" else "no") else toString v;
      logindConf = ''
        [Login]
        ${builtins.concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${formatValue v}") effectiveSettings)}
      '';
    in
    if !options.enable then
      { }
    else
      {
        services.logind.settings = effectiveSettings;

        environment.etc."systemd/logind.conf".text = logindConf;
      };
}
