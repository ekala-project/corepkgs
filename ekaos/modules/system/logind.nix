# Systemd-logind session management
# Handles power events, session tracking, and user session lifecycle
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.logind;

  # Generate logind.conf
  logindConf =
    let
      formatValue = v: if isBool v then (if v then "yes" else "no") else toString v;
      lines = mapAttrsToList (k: v: "${k}=${formatValue v}") cfg.settings;
    in
    ''
      [Login]
      ${concatStringsSep "\n" lines}
    '';

in

{
  options.services.logind = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable systemd-logind session management.";
    };

    settings = mkOption {
      type = types.attrsOf (
        types.oneOf [
          types.bool
          types.int
          types.str
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

  config = mkIf cfg.enable {
    # Default settings
    services.logind.settings = {
      KillUserProcesses = mkDefault false;
      HandlePowerKey = mkDefault "poweroff";
      HandleLidSwitch = mkDefault "suspend";
      IdleAction = mkDefault "ignore";
    };

    environment.etc."systemd/logind.conf".text = logindConf;
  };
}
