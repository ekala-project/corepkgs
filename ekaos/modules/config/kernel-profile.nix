# Kernel tuning profiles
#
# Selects runtime sysctl values, kernel boot parameters, and power management
# defaults appropriate for a given workload.  Compile-time kernel config
# (PREEMPT, HZ, BFQ, BBR, etc.) is set in common-config.nix and already
# targets interactive desktop use.  These profiles tune the *runtime* knobs
# on top of that base.
{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.boot.kernel.profile;

  # ── profile definitions ──────────────────────────────────────────────
  #
  # Each profile is an attrset of:
  #   sysctl   – merged into boot.kernel.sysctl
  #   params   – appended to boot.kernelParams
  #   power    – sets power.cpuFreqGovernor (null = don't touch)
  profiles = {

    reactive = {
      description = "Optimised for responsive desktop / laptop use (default)";
      sysctl = {
        # Swap less aggressively — keep working set in RAM
        "vm.swappiness" = 10;
        # Flush dirty pages earlier to avoid bursty I/O stalls
        "vm.dirty_ratio" = 10;
        "vm.dirty_background_ratio" = 5;
        # Prefer keeping dentries/inodes over page cache
        "vm.vfs_cache_pressure" = 50;
        # Moderate proactive compaction to reduce allocation stalls
        "vm.compaction_proactiveness" = 20;
        # Limit watermark boost to reduce kswapd wake-ups
        "vm.watermark_boost_factor" = 1;
        # Lower watermark scale — reclaim starts closer to low watermark
        "vm.watermark_scale_factor" = 125;
        # Increase minimum free kbytes for smoother allocations (64 MiB)
        "vm.min_free_kbytes" = 65536;
      };
      params = [ ];
      power = null;
    };

    balanced = {
      description = "General purpose — moderate latency and power use";
      sysctl = {
        "vm.swappiness" = 30;
        "vm.dirty_ratio" = 15;
        "vm.dirty_background_ratio" = 5;
        "vm.vfs_cache_pressure" = 100;
        "vm.compaction_proactiveness" = 20;
      };
      params = [ ];
      power = null;
    };

    battery = {
      description = "Maximise battery life on laptops";
      sysctl = {
        # Allow more swap to free RAM earlier
        "vm.swappiness" = 60;
        # Let dirty pages accumulate longer — fewer disk wake-ups
        "vm.dirty_ratio" = 30;
        "vm.dirty_background_ratio" = 10;
        "vm.vfs_cache_pressure" = 100;
        # Disable proactive compaction to save CPU
        "vm.compaction_proactiveness" = 0;
      };
      params = [
        # Re-enable power-efficient workqueues even if the compiled default
        # were to change in the future
        "workqueue.power_efficient=1"
        # Deeper NMI watchdog sleep
        "nmi_watchdog=0"
      ];
      power = "powersave";
    };

    low-power = {
      description = "Embedded / always-on devices — minimise CPU wake-ups";
      sysctl = {
        "vm.swappiness" = 80;
        "vm.dirty_ratio" = 40;
        "vm.dirty_background_ratio" = 15;
        "vm.vfs_cache_pressure" = 150;
        "vm.compaction_proactiveness" = 0;
      };
      params = [
        "workqueue.power_efficient=1"
        "nmi_watchdog=0"
        "processor.max_cstate=5"
      ];
      power = "powersave";
    };

    performance = {
      description = "Workstation / compute — lowest latency, ignore power use";
      sysctl = {
        # Almost never swap
        "vm.swappiness" = 1;
        # Flush dirty pages eagerly to avoid stalls
        "vm.dirty_ratio" = 5;
        "vm.dirty_background_ratio" = 3;
        # Reclaim dentries/inodes aggressively in favour of data
        "vm.vfs_cache_pressure" = 50;
        # Maximum proactive compaction
        "vm.compaction_proactiveness" = 50;
        "vm.watermark_boost_factor" = 1;
        "vm.watermark_scale_factor" = 125;
        "vm.min_free_kbytes" = 131072;
        # Disable NUMA balancing overhead if not needed
        "kernel.numa_balancing" = 0;
      };
      params = [
        # Disable power-efficient workqueues for lowest latency
        "workqueue.power_efficient=0"
      ];
      power = "performance";
    };

  };

  chosen = profiles.${cfg};
in

{
  options.boot.kernel.profile = mkOption {
    type = types.enum (attrNames profiles);
    default = "reactive";
    example = "battery";
    description = ''
      Kernel tuning profile.  Selects runtime sysctl values, boot
      parameters, and a CPU frequency governor appropriate for the
      workload.

      Available profiles:
      ${concatStringsSep "\n" (mapAttrsToList (n: p: "- ${n}: ${p.description}") profiles)}
    '';
  };

  config = {
    boot.kernel.sysctl = mapAttrs (_: mkDefault) chosen.sysctl;

    boot.kernelParams = chosen.params;

    power.cpuFreqGovernor = mkIf (chosen.power != null) (mkDefault chosen.power);
  };
}
