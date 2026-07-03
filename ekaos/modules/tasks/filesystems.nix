# Filesystem mount point configuration
# Generates /etc/fstab from declarative fileSystems definitions
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  # Escape spaces/tabs for fstab
  escape =
    string:
    builtins.replaceStrings
      [
        " "
        "\t"
      ]
      [
        "\\040"
        "\\011"
      ]
      string;

  specialFSTypes = [
    "proc"
    "sysfs"
    "tmpfs"
    "ramfs"
    "devtmpfs"
    "devpts"
  ];

  fileSystems = filter (fs: fs.enable) (attrValues config.fileSystems);

  # Generate a single fstab line
  fstabLine =
    fs:
    let
      device = if fs.label != null then "/dev/disk/by-label/${escape fs.label}" else escape fs.device;
      mountPoint = escape fs.mountPoint;
      fsType = fs.fsType;
      options = concatStringsSep "," fs.options;
      dump = toString fs.dump;
      pass = toString fs.pass;
    in
    "${device} ${mountPoint} ${fsType} ${options} ${dump} ${pass}";

  # Special filesystems that are always present
  defaultFstab = ''
    # Special filesystems (managed by ekaos)
    proc /proc proc defaults 0 0
    sysfs /sys sysfs defaults 0 0
    devtmpfs /dev devtmpfs mode=0755,nosuid 0 0
    devpts /dev/pts devpts mode=0620,gid=3,nosuid,noexec 0 0
    tmpfs /run tmpfs mode=0755,nosuid,nodev,size=25% 0 0
    tmpfs /dev/shm tmpfs mode=1777,nosuid,nodev 0 0
  '';

  # User-defined filesystem entries
  userFstab = concatMapStringsSep "\n" fstabLine fileSystems;

  # Swap entries from swap.devices
  swapDevices = filter (d: d.enable) (config.swap.devices or [ ]);
  swapFstab = concatMapStringsSep "\n" (
    dev:
    let
      device = if dev.label or null != null then "/dev/disk/by-label/${dev.label}" else dev.device;
    in
    "${device} none swap ${concatStringsSep "," (dev.options or [ "defaults" ])} 0 0"
  ) swapDevices;

  fsSubmodule =
    { name, config, ... }:
    {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether to mount this filesystem.";
        };

        device = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "/dev/sda1";
          description = ''
            Block device, UUID tag, or NFS path.
            Set automatically when label is used.
            For special filesystems (tmpfs, proc, etc.), defaults to the fsType.
          '';
        };

        label = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "root";
          description = ''
            Label of the device. Sets device to /dev/disk/by-label/<label>.
          '';
        };

        mountPoint = mkOption {
          type = types.str;
          default = name;
          example = "/home";
          description = "Where to mount the filesystem.";
        };

        fsType = mkOption {
          type = types.str;
          default = "auto";
          example = "ext4";
          description = "Filesystem type (ext4, btrfs, xfs, vfat, nfs, tmpfs, etc.).";
        };

        options = mkOption {
          type = types.listOf types.str;
          default = [ "defaults" ];
          example = [
            "noatime"
            "discard"
          ];
          description = "Mount options.";
        };

        dump = mkOption {
          type = types.int;
          default = 0;
          description = "dump(8) period (0 = disabled).";
        };

        pass = mkOption {
          type = types.int;
          default = 0;
          description = "fsck pass number (0 = disabled, 1 = root, 2 = other).";
        };

        neededForBoot = mkOption {
          type = types.bool;
          default = false;
          description = "Whether this filesystem is required during early boot.";
        };
      };

      config = {
        # For special FS types, default device to the fsType name
        device = mkIf (elem config.fsType specialFSTypes) (mkDefault config.fsType);
      };
    };

in

{
  options = {
    fileSystems = mkOption {
      type = types.attrsOf (types.submodule fsSubmodule);
      default = { };
      example = literalExpression ''
        {
          "/" = { device = "/dev/sda1"; fsType = "ext4"; };
          "/home" = { device = "/dev/sda2"; fsType = "ext4"; options = [ "noatime" ]; };
          "/boot" = { label = "BOOT"; fsType = "vfat"; };
        }
      '';
      description = ''
        Declarative filesystem mount points.
        Each attribute name is used as the default mount point.
      '';
    };

    boot.tmp = {
      useTmpfs = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to mount /tmp as a tmpfs filesystem.
          When false, /tmp is a regular directory on the root filesystem.
        '';
      };

      tmpfsSize = mkOption {
        type = types.str;
        default = "50%";
        example = "2G";
        description = "Size of the /tmp tmpfs (percentage of RAM or absolute size).";
      };

      cleanOnBoot = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to clear /tmp on boot (only when not using tmpfs).";
      };
    };
  };

  config = {
    # Generate /etc/fstab with both special and user-defined filesystems
    environment.etc."fstab".text = ''
      # /etc/fstab: static filesystem configuration
      # Generated by ekaos

      ${defaultFstab}
      ${optionalString (userFstab != "") ''
        # User-defined filesystems
        ${userFstab}
      ''}
      ${optionalString config.boot.tmp.useTmpfs ''
        # /tmp as tmpfs
        tmpfs /tmp tmpfs mode=1777,nosuid,nodev,size=${config.boot.tmp.tmpfsSize} 0 0
      ''}
      ${optionalString (swapFstab != "") ''
        # Swap devices
        ${swapFstab}
      ''}
    '';

    # Mount user-defined filesystems and handle /tmp during activation
    system.activationScripts.filesystems = stringAfter [ "etc" ] ''
      # Mount any user-defined filesystems not already mounted
      ${concatMapStringsSep "\n" (
        fs:
        optionalString (!(elem fs.fsType specialFSTypes)) ''
          if ! mountpoint -q ${escapeShellArg fs.mountPoint} 2>/dev/null; then
            mkdir -p ${escapeShellArg fs.mountPoint}
            echo "Mounting ${fs.mountPoint}..."
            mount ${escapeShellArg fs.mountPoint} 2>/dev/null || true
          fi
        ''
      ) fileSystems}

      ${optionalString (!config.boot.tmp.useTmpfs && config.boot.tmp.cleanOnBoot) ''
        # Clean /tmp on boot
        echo "Cleaning /tmp..."
        find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
      ''}
    '';
  };
}
