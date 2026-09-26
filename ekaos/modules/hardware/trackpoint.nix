# Adios port of ekaos/modules/hardware/trackpoint.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Enable sensitivity and speed configuration for TrackPoints.";
    };

    sensitivity = {
      type = types.int;
      default = 128;
      description = "TrackPoint sensitivity (0-255).";
    };

    speed = {
      type = types.int;
      default = 97;
      description = "Speed of the TrackPoint cursor (0-255).";
    };

    emulateWheel = {
      type = types.bool;
      default = false;
      description = "Enable scrolling while holding the middle mouse button.";
    };

    device = {
      type = types.string;
      default = "TPPS/2 IBM TrackPoint";
      description = ''
        The device name of the TrackPoint.
        Some newer devices use "TPPS/2 Elan TrackPoint".
      '';
    };
  };

  assertions = [
    {
      verify = { options }: options.sensitivity >= 0 && options.sensitivity <= 255;
      explain = { options }: "sensitivity must be 0-255, got ${toString options.sensitivity}";
    }
    {
      verify = { options }: options.speed >= 0 && options.speed <= 255;
      explain = { options }: "speed must be 0-255, got ${toString options.speed}";
    }
  ];

  impl =
    { options, ... }:
    let
      boolToStr = val: if val then "1" else "0";
    in
    if options.enable then
      {
        # Configure TrackPoint sensitivity and speed via udev
        services.udev.extraRules = ''
          ACTION=="add|change", SUBSYSTEM=="input", ATTR{name}=="${options.device}", \
            ATTR{device/sensitivity}="${toString options.sensitivity}", \
            ATTR{device/speed}="${toString options.speed}"
        '';

        # Set TrackPoint parameters via sysfs at activation
        # TODO(adios-cutover): legacy stringAfter [ "etc" ] ordering lost.
        system.activationScripts.trackpoint = ''
          for tp in /sys/devices/platform/i8042/serio1/serio2 /sys/devices/rmi4-00/rmi4-00.fn03; do
            if [ -d "$tp" ]; then
              [ -w "$tp/sensitivity" ] && echo "${toString options.sensitivity}" > "$tp/sensitivity" 2>/dev/null || true
              [ -w "$tp/speed" ] && echo "${toString options.speed}" > "$tp/speed" 2>/dev/null || true
            fi
          done
        '';
      }
    else
      { };
}
