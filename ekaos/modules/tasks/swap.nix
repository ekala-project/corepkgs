# Adios port of ekaos/modules/tasks/swap.nix.
#
# Tree path: tasks/swap is parent.tasks.swap.
# Self-contained; no cross-module reads. The legacy `config = mkMerge
# [...]` becomes lib.merge.attrs.recursively with two conditional
# mutators (lib = adios.lib from the header).
# TODO(adios-cutover): devices is types.listOf types.attrs; legacy swap
# submodule validation lost (expected keys: enable, device, label, size,
# priority, options, randomEncryption.{enable,cipher,keySize}). Element
# defaults are applied via `or` fallbacks in impl.
{
  types,
  lib,
  pkgs,
  ...
}:

{
  options = {
    devices = {
      type = types.listOf types.attrs;
      default = [ ];
      example = [
        { device = "/dev/sda3"; }
        {
          device = "/swapfile";
          size = 4096;
        }
      ];
      description = ''
        List of swap devices or swap files. Each entry may set enable
        (default true), device, label, size (MiB, for swap files),
        priority, options (default ["defaults"]), and
        randomEncryption.{enable,cipher,keySize}.
      '';
    };

    zram = {
      description = "Zram-based compressed swap.";
      options = {
        enable = {
          type = types.bool;
          default = false;
          description = "Whether to enable zram-based compressed swap.";
        };

        memoryPercent = {
          type = types.int;
          default = 50;
          description = "Percentage of RAM to use for zram swap.";
        };

        algorithm = {
          type = types.enum "zram-algorithm" [
            "lzo"
            "lz4"
            "zstd"
          ];
          default = "zstd";
          description = "Compression algorithm for zram.";
        };
      };
    };
  };

  assertions = [
    {
      verify = { options, inputs }: options.zram.memoryPercent >= 1 && options.zram.memoryPercent <= 100;
      explain =
        { options, inputs }:
        "zram.memoryPercent must be 1-100, got ${toString options.zram.memoryPercent}";
    }
  ];

  impl =
    { options, inputs }:
    let
      enabledDevices = builtins.filter (d: (d.enable or true)) options.devices;

      # Generate fstab swap entries (kept for parity; the fstab itself is
      # emitted by tasks/filesystems.nix, as in legacy).
      swapFstabLines = builtins.concatStringsSep "\n" (
        builtins.map (
          dev:
          let
            device = if (dev.label or null) != null then "/dev/disk/by-label/${dev.label}" else dev.device;
            entryOptions = builtins.concatStringsSep "," (dev.options or [ "defaults" ]);
          in
          "${device} none swap ${entryOptions} 0 0"
        ) enabledDevices
      );
      _lines = swapFstabLines;
    in
    lib.merge.attrs.recursively {
      mutators = [
        # Append swap entries to fstab
        (
          if enabledDevices != [ ] then
            {
              system.activationScripts.swap = {
                deps = [
                  "etc"
                  "filesystems"
                ];
                text = ''
                  ${builtins.concatStringsSep "\n" (
                    builtins.map (
                      dev:
                      let
                        device = if (dev.label or null) != null then "/dev/disk/by-label/${dev.label}" else dev.device;
                      in
                      ''
                        # Activate swap: ${device}
                        ${
                          if (dev.size or null) != null then
                            ''
                              # Create swap file if it doesn't exist
                              if [ ! -f "${device}" ]; then
                                echo "Creating swap file ${device} (${toString dev.size} MiB)..."
                                dd if=/dev/zero of="${device}" bs=1M count=${toString dev.size} 2>/dev/null
                                chmod 600 "${device}"
                                ${pkgs.util-linux}/bin/mkswap "${device}"
                              fi
                            ''
                          else
                            ""
                        }
                        ${pkgs.util-linux}/bin/swapon ${
                          if (dev.priority or null) != null then "-p ${toString dev.priority}" else ""
                        } "${device}" 2>/dev/null || true
                      ''
                    ) enabledDevices
                  )}
                '';
              };
            }
          else
            { }
        )

        # Zram swap
        (
          if options.zram.enable then
            {
              boot.kernelModules = [ "zram" ];

              system.activationScripts.zram = {
                deps = [ "etc" ];
                text = ''
                  # Set up zram swap
                  if [ -e /sys/block/zram0 ]; then
                    echo "Configuring zram swap..."
                    mem_total=$(${pkgs.gawk}/bin/awk '/MemTotal/ {print $2}' /proc/meminfo)
                    zram_size=$((mem_total * ${toString options.zram.memoryPercent} / 100 * 1024))
                    echo ${options.zram.algorithm} > /sys/block/zram0/comp_algorithm 2>/dev/null || true
                    echo $zram_size > /sys/block/zram0/disksize
                    ${pkgs.util-linux}/bin/mkswap /dev/zram0
                    ${pkgs.util-linux}/bin/swapon -p 100 /dev/zram0
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
