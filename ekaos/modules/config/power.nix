# Power management configuration
# Ported from nixpkgs powerManagement.* as power.*
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.power;
in

{
  options = {
    power = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable power management features.
        '';
      };

      cpuFreqGovernor = mkOption {
        type = types.nullOr (
          types.enum [
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

      scsiLinkPolicy = mkOption {
        type = types.nullOr (
          types.enum [
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

      bootCommands = mkOption {
        type = types.lines;
        default = "";
        description = "Shell commands to execute during boot for power management setup.";
      };

      resumeCommands = mkOption {
        type = types.lines;
        default = "";
        description = "Shell commands to execute when resuming from suspend.";
      };

      powerUpCommands = mkOption {
        type = types.lines;
        default = "";
        description = "Shell commands to execute when switching to AC power.";
      };

      powerDownCommands = mkOption {
        type = types.lines;
        default = "";
        description = "Shell commands to execute when switching to battery.";
      };

      powertop = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable PowerTOP auto-tuning at boot.

            Automatically sets all tunable options to their most
            power-efficient setting.
          '';
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # CPU frequency governor
    (mkIf (cfg.cpuFreqGovernor != null) {
      boot.kernelModules = [ "cpufreq_${cfg.cpuFreqGovernor}" ];
      system.activationScripts.cpufreq = stringAfter [ "etc" ] ''
        for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
          [ -w "$gov" ] && echo "${cfg.cpuFreqGovernor}" > "$gov" 2>/dev/null || true
        done
      '';
    })

    # SCSI link power management
    (mkIf (cfg.scsiLinkPolicy != null) {
      system.activationScripts.scsi-link-policy = stringAfter [ "etc" ] ''
        for policy in /sys/class/scsi_host/host*/link_power_management_policy; do
          [ -w "$policy" ] && echo "${cfg.scsiLinkPolicy}" > "$policy" 2>/dev/null || true
        done
      '';
    })

    # Boot power commands
    (mkIf (cfg.bootCommands != "") {
      boot.postBootCommands = mkAfter cfg.bootCommands;
    })

    # PowerTOP auto-tune
    (mkIf cfg.powertop.enable {
      # TODO: requires powertop package
      environment.systemPackages = [
        (pkgs.powertop or (builtins.trace "Warning: powertop not available" pkgs.coreutils))
      ];

      system.activationScripts.powertop = stringAfter [ "etc" ] ''
        if command -v powertop >/dev/null 2>&1; then
          echo "Running PowerTOP auto-tune..."
          powertop --auto-tune 2>/dev/null || true
        fi
      '';
    })
  ]);
}
