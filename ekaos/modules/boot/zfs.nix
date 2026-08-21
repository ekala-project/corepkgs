# ZFS boot support
# Provides ZFS pool import at boot and ZFS service timers
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.boot.zfs;
  cfgTrim = config.services.zfs.trim;
  cfgScrub = config.services.zfs.autoScrub;

  zfsPackage = config.boot.zfs.package;

in

{
  options = {
    boot.zfs = {
      package = mkOption {
        type = types.package;
        default = pkgs.zfs or (throw "ZFS package not available in core-pkgs");
        defaultText = literalExpression "pkgs.zfs";
        description = "The ZFS userspace package to use.";
      };

      extraPools = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "tank"
          "data"
        ];
        description = ''
          List of ZFS pools to import at boot (Stage 2).

          These pools will be imported by the ZFS import service after
          the root filesystem is mounted.
        '';
      };

      forceImportAll = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to force import all ZFS pools.

          When true, adds -f flag to zpool import. Use with caution —
          this can import pools that were not cleanly exported.
        '';
      };

      devNodes = mkOption {
        type = types.str;
        default = "/dev/disk/by-id";
        example = "/dev";
        description = ''
          Device node path to use for pool import.

          Using /dev/disk/by-id is recommended for stable device naming.
        '';
      };

      requestEncryptionCredentials = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to prompt for encryption credentials during boot
          for encrypted ZFS datasets.
        '';
      };
    };

    boot.supportedFilesystems = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "zfs"
        "btrfs"
      ];
      description = ''
        Filesystems supported by the booted system (Stage 2).

        This complements boot.initrd.supportedFilesystems which handles
        Stage 1 (initramfs) filesystem support.
      '';
    };

    services.zfs.trim = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable periodic ZFS TRIM.

          Sends TRIM commands to the underlying devices of all
          imported pools. Useful for SSDs.
        '';
      };

      interval = mkOption {
        type = types.str;
        default = "weekly";
        example = "daily";
        description = "How often to run ZFS TRIM (calendar spec).";
      };
    };

    services.zfs.autoScrub = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable periodic ZFS scrubbing.

          Scrubbing verifies data integrity and repairs silent corruption.
        '';
      };

      interval = mkOption {
        type = types.str;
        default = "monthly";
        example = "weekly";
        description = "How often to run ZFS scrub (calendar spec).";
      };

      pools = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "tank" ];
        description = ''
          List of pools to scrub. If empty, all imported pools are scrubbed.
        '';
      };
    };
  };

  config = mkMerge [
    # ZFS initrd support when "zfs" is in boot.initrd.supportedFilesystems
    (mkIf (elem "zfs" config.boot.initrd.supportedFilesystems) {
      boot.initrd.kernelModules = [ "zfs" ];
      boot.initrd.extraUtilsCommands = ''
        copy_bin_and_libs ${zfsPackage}/bin/zpool
        copy_bin_and_libs ${zfsPackage}/bin/zfs
        copy_bin_and_libs ${zfsPackage}/bin/mount.zfs
      '';
    })

    # ZFS Stage 2 support
    (mkIf (elem "zfs" config.boot.supportedFilesystems || cfg.extraPools != [ ]) {
      environment.systemPackages = [ zfsPackage ];

      boot.kernelModules = [ "zfs" ];

      # ZFS needs hostId for pool import safety
      assertions = [
        {
          assertion = config.networking.hostId != null;
          message = "ZFS requires networking.hostId to be set for safe pool import.";
        }
      ];

      # Import pools at boot
      system.activationScripts.zfs-import = mkIf (cfg.extraPools != [ ]) (
        stringAfter [ "etc" "users" ] ''
          echo "Importing ZFS pools..."
          ${concatMapStringsSep "\n" (pool: ''
            if ! ${zfsPackage}/bin/zpool list ${pool} >/dev/null 2>&1; then
              echo "Importing ZFS pool: ${pool}"
              ${zfsPackage}/bin/zpool import \
                ${optionalString cfg.forceImportAll "-f"} \
                -d ${cfg.devNodes} \
                ${pool} || echo "Warning: Failed to import pool ${pool}"
            fi
          '') cfg.extraPools}

          # Mount all ZFS datasets
          ${zfsPackage}/bin/zfs mount -a || true
        ''
      );
    })

    # ZFS TRIM timer
    (mkIf cfgTrim.enable {
      timers.zfs-trim = {
        enable = true;
        description = "ZFS TRIM";
        schedule.calendar = cfgTrim.interval;
        schedule.persistent = true;
        script = "${zfsPackage}/bin/zpool trim -a";
        user = "root";
      };
    })

    # ZFS scrub timer
    (mkIf cfgScrub.enable {
      timers.zfs-scrub = {
        enable = true;
        description = "ZFS Scrub";
        schedule.calendar = cfgScrub.interval;
        schedule.persistent = true;
        script =
          if cfgScrub.pools == [ ] then
            "${zfsPackage}/bin/zpool scrub $(${zfsPackage}/bin/zpool list -H -o name)"
          else
            concatMapStringsSep "\n" (pool: "${zfsPackage}/bin/zpool scrub ${pool}") cfgScrub.pools;
        user = "root";
      };
    })
  ];
}
