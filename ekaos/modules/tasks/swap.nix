# Swap device configuration
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.swap;
  enabledDevices = filter (d: d.enable) cfg.devices;

  # Generate fstab swap entries
  swapFstabLines = concatMapStringsSep "\n" (
    dev:
    let
      device = if dev.label != null then "/dev/disk/by-label/${dev.label}" else dev.device;
      options = concatStringsSep "," dev.options;
    in
    "${device} none swap ${options} 0 0"
  ) enabledDevices;

  swapSubmodule = {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable this swap device.";
      };

      device = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/dev/sda3";
        description = ''
          Path to the swap device or swap file.
          Set automatically when label is used.
        '';
      };

      label = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "swap";
        description = "Label of the swap partition.";
      };

      size = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 4096;
        description = ''
          Size in MiB. Only used when creating a swap file
          (device is a regular file path, not a block device).
        '';
      };

      priority = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 100;
        description = "Swap priority (higher = preferred). null uses kernel default.";
      };

      options = mkOption {
        type = types.listOf types.str;
        default = [ "defaults" ];
        description = "Mount options for the swap entry in fstab.";
      };

      randomEncryption = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Encrypt swap with a random key on each boot.
            Data is not recoverable after reboot.
          '';
        };

        cipher = mkOption {
          type = types.str;
          default = "aes-xts-plain64";
          description = "Encryption cipher for random swap encryption.";
        };

        keySize = mkOption {
          type = types.int;
          default = 256;
          description = "Key size in bits.";
        };
      };
    };
  };

in

{
  options.swap = {
    devices = mkOption {
      type = types.listOf (types.submodule swapSubmodule);
      default = [ ];
      example = literalExpression ''
        [
          { device = "/dev/sda3"; }
          { device = "/swapfile"; size = 4096; }
        ]
      '';
      description = "List of swap devices or swap files.";
    };

    zram = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable zram-based compressed swap.";
      };

      memoryPercent = mkOption {
        type = types.int;
        default = 50;
        description = "Percentage of RAM to use for zram swap.";
      };

      algorithm = mkOption {
        type = types.enum [
          "lzo"
          "lz4"
          "zstd"
        ];
        default = "zstd";
        description = "Compression algorithm for zram.";
      };
    };
  };

  config = mkMerge [
    # Append swap entries to fstab
    (mkIf (enabledDevices != [ ]) {
      system.activationScripts.swap =
        stringAfter
          [
            "etc"
            "filesystems"
          ]
          ''
            ${concatMapStringsSep "\n" (
              dev:
              let
                device = if dev.label != null then "/dev/disk/by-label/${dev.label}" else dev.device;
              in
              ''
                # Activate swap: ${device}
                ${optionalString (dev.size != null) ''
                  # Create swap file if it doesn't exist
                  if [ ! -f "${device}" ]; then
                    echo "Creating swap file ${device} (${toString dev.size} MiB)..."
                    dd if=/dev/zero of="${device}" bs=1M count=${toString dev.size} 2>/dev/null
                    chmod 600 "${device}"
                    ${pkgs.util-linux}/bin/mkswap "${device}"
                  fi
                ''}
                ${pkgs.util-linux}/bin/swapon ${
                  optionalString (dev.priority != null) "-p ${toString dev.priority}"
                } "${device}" 2>/dev/null || true
              ''
            ) enabledDevices}
          '';
    })

    # Zram swap
    (mkIf cfg.zram.enable {
      boot.kernelModules = [ "zram" ];

      system.activationScripts.zram = stringAfter [ "etc" ] ''
        # Set up zram swap
        if [ -e /sys/block/zram0 ]; then
          echo "Configuring zram swap..."
          mem_total=$(${pkgs.gawk}/bin/awk '/MemTotal/ {print $2}' /proc/meminfo)
          zram_size=$((mem_total * ${toString cfg.zram.memoryPercent} / 100 * 1024))
          echo ${cfg.zram.algorithm} > /sys/block/zram0/comp_algorithm 2>/dev/null || true
          echo $zram_size > /sys/block/zram0/disksize
          ${pkgs.util-linux}/bin/mkswap /dev/zram0
          ${pkgs.util-linux}/bin/swapon -p 100 /dev/zram0
        fi
      '';
    })
  ];
}
