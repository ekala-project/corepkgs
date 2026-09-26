# Adios port of ekaos/modules/boot/zfs.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{
  types,
  lib,
  pkgs,
  ...
}:

{
  options = {
    # Legacy path: boot.zfs.package.
    package = {
      type = types.nullOr types.derivation;
      default = pkgs.zfs or null;
      description = "The ZFS userspace package to use.";
    };

    # Legacy path: boot.zfs.extraPools.
    extraPools = {
      type = types.listOf types.string;
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

    # Legacy path: boot.zfs.forceImportAll.
    forceImportAll = {
      type = types.bool;
      default = false;
      description = ''
        Whether to force import all ZFS pools.

        When true, adds -f flag to zpool import. Use with caution —
        this can import pools that were not cleanly exported.
      '';
    };

    # Legacy path: boot.zfs.devNodes.
    devNodes = {
      type = types.string;
      default = "/dev/disk/by-id";
      example = "/dev";
      description = ''
        Device node path to use for pool import.

        Using /dev/disk/by-id is recommended for stable device naming.
      '';
    };

    # Legacy path: boot.zfs.requestEncryptionCredentials.
    requestEncryptionCredentials = {
      type = types.bool;
      default = true;
      description = ''
        Whether to prompt for encryption credentials during boot
        for encrypted ZFS datasets.
      '';
    };

    # Legacy path: boot.supportedFilesystems (Stage 2 filesystems).
    supportedFilesystems = {
      type = types.listOf types.string;
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

    # Legacy path: services.zfs.trim.enable.
    trimEnable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable periodic ZFS TRIM.

        Sends TRIM commands to the underlying devices of all
        imported pools. Useful for SSDs.
      '';
    };

    # Legacy path: services.zfs.trim.interval.
    trimInterval = {
      type = types.string;
      default = "weekly";
      example = "daily";
      description = "How often to run ZFS TRIM (calendar spec).";
    };

    # Legacy path: services.zfs.autoScrub.enable.
    autoScrubEnable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable periodic ZFS scrubbing.

        Scrubbing verifies data integrity and repairs silent corruption.
      '';
    };

    # Legacy path: services.zfs.autoScrub.interval.
    autoScrubInterval = {
      type = types.string;
      default = "monthly";
      example = "weekly";
      description = "How often to run ZFS scrub (calendar spec).";
    };

    # Legacy path: services.zfs.autoScrub.pools.
    autoScrubPools = {
      type = types.listOf types.string;
      default = [ ];
      example = [ "tank" ];
      description = ''
        List of pools to scrub. If empty, all imported pools are scrubbed.
      '';
    };
  };

  inputs = {
    initrd.from = { parent }: parent.initrd;
    networking.from = { root }: root.networking;
  };

  assertions = [
    {
      verify =
        { options, ... }:
        !(builtins.elem "zfs" options.supportedFilesystems || options.extraPools != [ ])
        || (options.package != null);
      explain = { options, ... }: "package option must be set when zfs is used (zfs is not in core-pkgs)";
    }
    {
      # Legacy asserted this only inside the Stage-2 branch; the branch
      # condition is encoded here.
      verify =
        { options, inputs }:
        !(builtins.elem "zfs" options.supportedFilesystems || options.extraPools != [ ])
        || inputs.networking.hostId != null;
      explain = { options, inputs }: "ZFS requires networking.hostId to be set for safe pool import.";
    }
  ];

  impl =
    { options, inputs }:
    lib.merge.attrs.recursively {
      mutators = [
        (
          if builtins.elem "zfs" inputs.initrd.supportedFilesystems then
            {
              boot.initrd.kernelModules = [ "zfs" ];
              boot.initrd.extraUtilsCommands = ''
                copy_bin_and_libs ${options.package}/bin/zpool
                copy_bin_and_libs ${options.package}/bin/zfs
                copy_bin_and_libs ${options.package}/bin/mount.zfs
              '';
            }
          else
            { }
        )

        (
          if builtins.elem "zfs" options.supportedFilesystems || options.extraPools != [ ] then
            lib.merge.attrs.recursively {
              mutators = [
                {
                  environment.systemPackages = [ options.package ];

                  boot.kernelModules = [ "zfs" ];
                }

                (
                  if options.extraPools != [ ] then
                    {
                      # TODO(adios-cutover): stringAfter [ "etc" "users" ] ordering dropped.
                      system.activationScripts.zfs-import = ''
                        echo "Importing ZFS pools..."
                        ${builtins.concatStringsSep "\n" (pool: ''
                          if ! ${options.package}/bin/zpool list ${pool} >/dev/null 2>&1; then
                            echo "Importing ZFS pool: ${pool}"
                            ${options.package}/bin/zpool import \
                              ${if options.forceImportAll then "-f" else ""} \
                              -d ${options.devNodes} \
                              ${pool} || echo "Warning: Failed to import pool ${pool}"
                          fi
                        '') options.extraPools}

                        # Mount all ZFS datasets
                        ${options.package}/bin/zfs mount -a || true
                      '';
                    }
                  else
                    { }
                )
              ];
            }
          else
            { }
        )

        (
          if options.trimEnable then
            {
              timers.zfs-trim = {
                enable = true;
                description = "ZFS TRIM";
                schedule.calendar = options.trimInterval;
                schedule.persistent = true;
                script = "${options.package}/bin/zpool trim -a";
                user = "root";
              };
            }
          else
            { }
        )

        (
          if options.autoScrubEnable then
            {
              timers.zfs-scrub = {
                enable = true;
                description = "ZFS Scrub";
                schedule.calendar = options.autoScrubInterval;
                schedule.persistent = true;
                script =
                  if options.autoScrubPools == [ ] then
                    "${options.package}/bin/zpool scrub $(${options.package}/bin/zpool list -H -o name)"
                  else
                    builtins.concatStringsSep "\n" (
                      builtins.map (pool: "${options.package}/bin/zpool scrub ${pool}") options.autoScrubPools
                    );
                user = "root";
              };
            }
          else
            { }
        )
      ];
    };
  # Note: legacy option boot.zfs.requestEncryptionCredentials is accepted and
  # exposed for other modules but has no config effect here (same as legacy).
}
