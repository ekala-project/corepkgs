# Adios port of ekaos/modules/config/power.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{
  types,
  lib,
  pkgs,
  ...
}:

{
  options = {
    enable = {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable power management features.
      '';
    };

    cpuFreqGovernor = {
      type = types.nullOr (
        types.enum "cpu-freq-governor" [
          "performance"
          "powersave"
          "ondemand"
          "conservative"
          "schedutil"
        ]
      );
      default = null;
      example = "powersave";
      description = ''
        CPU frequency scaling governor.

        - performance: Always run at max frequency
        - powersave: Always run at min frequency
        - ondemand: Scale based on load (legacy)
        - conservative: Scale gradually (legacy)
        - schedutil: Scheduler-driven (modern, recommended)
      '';
    };

    scsiLinkPolicy = {
      type = types.nullOr (
        types.enum "scsi-link-policy" [
          "min_power"
          "max_performance"
          "medium_power"
          "med_power_with_dipm"
        ]
      );
      default = null;
      example = "med_power_with_dipm";
      description = ''
        SATA link power management policy.

        - max_performance: No power saving
        - medium_power: Moderate savings
        - med_power_with_dipm: Best balance
        - min_power: Maximum savings (may increase latency)
      '';
    };

    bootCommands = {
      type = types.string;
      default = "";
      description = "Shell commands to execute during boot for power management setup.";
    };

    # Declared by the legacy module but never read by its config section;
    # kept so the interface stays complete.
    resumeCommands = {
      type = types.string;
      default = "";
      description = "Shell commands to execute when resuming from suspend.";
    };

    powerUpCommands = {
      type = types.string;
      default = "";
      description = "Shell commands to execute when switching to AC power.";
    };

    powerDownCommands = {
      type = types.string;
      default = "";
      description = "Shell commands to execute when switching to battery.";
    };

    powertop = {
      options = {
        enable = {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable PowerTOP auto-tuning at boot.

            Automatically sets all tunable options to their most
            power-efficient setting.
          '';
        };
      };
      description = "PowerTOP auto-tuning settings.";
    };
  };

  impl =
    { options, ... }:
    if !options.enable then
      { }
    else
      lib.merge.attrs.recursively {
        mutators = [
          # CPU frequency governor
          (
            if (options.cpuFreqGovernor != null) then
              {
                boot.kernelModules = [ "cpufreq_${options.cpuFreqGovernor}" ];
                system.activationScripts.cpufreq = {
                  deps = [ "etc" ];
                  text = ''
                    for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                      [ -w "$gov" ] && echo "${options.cpuFreqGovernor}" > "$gov" 2>/dev/null || true
                    done
                  '';
                };
              }
            else
              { }
          )

          # SCSI link power management
          (
            if (options.scsiLinkPolicy != null) then
              {
                system.activationScripts.scsi-link-policy = {
                  deps = [ "etc" ];
                  text = ''
                    for policy in /sys/class/scsi_host/host*/link_power_management_policy; do
                      [ -w "$policy" ] && echo "${options.scsiLinkPolicy}" > "$policy" 2>/dev/null || true
                    done
                  '';
                };
              }
            else
              { }
          )

          # Boot power commands
          (
            if (options.bootCommands != "") then
              {
                # TODO(adios-cutover): ordering lost (was mkAfter).
                boot.postBootCommands = options.bootCommands;
              }
            else
              { }
          )

          # PowerTOP auto-tune
          (
            if options.powertop.enable then
              {
                # TODO: requires powertop package
                environment.systemPackages = [
                  (pkgs.powertop or (builtins.trace "Warning: powertop not available" pkgs.coreutils))
                ];

                system.activationScripts.powertop = {
                  deps = [ "etc" ];
                  text = ''
                    if command -v powertop >/dev/null 2>&1; then
                      echo "Running PowerTOP auto-tune..."
                      powertop --auto-tune 2>/dev/null || true
                    fi
                  '';
                };
              }
            else
              { }
          )
        ];
      };
}
