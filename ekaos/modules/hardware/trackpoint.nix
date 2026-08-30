# ThinkPad TrackPoint configuration
# Ported from nixpkgs/nixos/modules/tasks/trackpoint.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.hardware.trackpoint;
  boolToStr = val: if val then "1" else "0";
in
{
  options.hardware.trackpoint = {
    enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = "Enable sensitivity and speed configuration for TrackPoints.";
    };

    sensitivity = lib.mkOption {
      default = 128;
      type = lib.types.int;
      description = "TrackPoint sensitivity (0-255).";
    };

    speed = lib.mkOption {
      default = 97;
      type = lib.types.int;
      description = "Speed of the TrackPoint cursor (0-255).";
    };

    emulateWheel = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = "Enable scrolling while holding the middle mouse button.";
    };

    device = lib.mkOption {
      default = "TPPS/2 IBM TrackPoint";
      type = lib.types.str;
      description = ''
        The device name of the TrackPoint.
        Some newer devices use "TPPS/2 Elan TrackPoint".
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # TODO: services.udev.extraRules not yet available in ekaOS
    # Configure TrackPoint sensitivity and speed via udev
    # services.udev.extraRules = ''
    #   ACTION=="add|change", SUBSYSTEM=="input", ATTR{name}=="${cfg.device}", \
    #     ATTR{device/sensitivity}="${toString cfg.sensitivity}", \
    #     ATTR{device/speed}="${toString cfg.speed}"
    # '';

    # Set TrackPoint parameters via sysfs at activation
    system.activationScripts.trackpoint = lib.stringAfter [ "etc" ] ''
      for tp in /sys/devices/platform/i8042/serio1/serio2 /sys/devices/rmi4-00/rmi4-00.fn03; do
        if [ -d "$tp" ]; then
          [ -w "$tp/sensitivity" ] && echo "${toString cfg.sensitivity}" > "$tp/sensitivity" 2>/dev/null || true
          [ -w "$tp/speed" ] && echo "${toString cfg.speed}" > "$tp/speed" 2>/dev/null || true
        fi
      done
    '';
  };
}
