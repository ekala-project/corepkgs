# Adios port of ekaos/modules/tasks/filesystems.nix.
#
# Tree path: tasks/filesystems is parent.tasks.filesystems.
# Generates /etc/fstab from declarative fileSystems definitions.
# Reads boot tmpfs sizes via inputs.bootSizes (parent.boot."stage-2":
# boot.devSize/runSize/devShmSize) and swap devices via inputs.swapDev
# (parent.tasks.swap, option devices).
# TODO(adios-cutover): fileSystems / boot.specialFileSystems are
# types.attrsOf types.attrs; legacy fs-submodule validation and per-field
# defaults lost. Element defaults (enable=true, device rule below,
# mountPoint=name, fsType="auto", options=["defaults"], dump/pass=0,
# neededForBoot=false) are applied via normalisation in impl.
# TODO(adios-cutover): priority lost (was mkDefault): for special FS
# types the device default (fsType name) is applied unconditionally when
# device is unset, instead of as a lower-priority default.
{ types, ... }:

let
  escapeShellArg = s: "'${builtins.replaceStrings [ "'" ] [ "'\\''" ] (toString s)}'";

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

  # Apply legacy fs-submodule defaults to a raw attrset entry.
  normalizeFs =
    name: fs:
    let
      fsType = fs.fsType or "auto";
      device =
        if (fs.device or null) != null then
          fs.device
        else if builtins.elem fsType specialFSTypes then
          fsType
        else
          throw "fileSystems.${name}: no device or label set";
    in
    fs
    // {
      enable = fs.enable or true;
      inherit device;
      label = fs.label or null;
      mountPoint = fs.mountPoint or name;
      inherit fsType;
      options = fs.options or [ "defaults" ];
      dump = fs.dump or 0;
      pass = fs.pass or 0;
      neededForBoot = fs.neededForBoot or false;
    };

  # Generate a single fstab line
  fstabLine =
    fs:
    let
      device = if fs.label != null then "/dev/disk/by-label/${escape fs.label}" else escape fs.device;
      mountPoint = escape fs.mountPoint;
      fsType = fs.fsType;
      options = builtins.concatStringsSep "," fs.options;
      dump = toString fs.dump;
      pass = toString fs.pass;
    in
    "${device} ${mountPoint} ${fsType} ${options} ${dump} ${pass}";
in

{
  options = {
    # Legacy was internal; internal dropped, kept for shape parity.
    specialFileSystems = {
      type = types.attrsOf types.attrs;
      default = { };
      description = ''
        Special filesystems that are mounted very early during boot.

        These use the same submodule structure as fileSystems but are
        handled separately to ensure they are available before other
        mounts.
      '';
    };

    fileSystems = {
      type = types.attrsOf types.attrs;
      default = { };
      example = {
        "/" = {
          device = "/dev/sda1";
          fsType = "ext4";
        };
        "/home" = {
          device = "/dev/sda2";
          fsType = "ext4";
          options = [ "noatime" ];
        };
        "/boot" = {
          label = "BOOT";
          fsType = "vfat";
        };
      };
      description = ''
        Declarative filesystem mount points.
        Each attribute name is used as the default mount point.
      '';
    };

    tmp = {
      description = "Behaviour of /tmp.";
      options = {
        useTmpfs = {
          type = types.bool;
          default = false;
          description = ''
            Whether to mount /tmp as a tmpfs filesystem.
            When false, /tmp is a regular directory on the root filesystem.
          '';
        };

        tmpfsSize = {
          type = types.string;
          default = "50%";
          example = "2G";
          description = "Size of the /tmp tmpfs (percentage of RAM or absolute size).";
        };

        cleanOnBoot = {
          type = types.bool;
          default = false;
          description = "Whether to clear /tmp on boot (only when not using tmpfs).";
        };
      };
    };
  };

  inputs = {
    bootSizes.from = { root }: root.boot."stage-2";
    swapDev.from = { parent }: parent.swap;
  };

  impl =
    { options, inputs }:
    let
      allFs = builtins.attrValues (builtins.mapAttrs normalizeFs options.fileSystems);
      fileSystems = builtins.filter (fs: fs.enable) allFs;

      # Special filesystems that are always present
      defaultFstab = ''
        # Special filesystems (managed by ekaos)
        proc /proc proc defaults 0 0
        sysfs /sys sysfs defaults 0 0
        devtmpfs /dev devtmpfs mode=0755,nosuid,size=${inputs.bootSizes.devSize} 0 0
        devpts /dev/pts devpts mode=0620,gid=3,nosuid,noexec 0 0
        tmpfs /run tmpfs mode=0755,nosuid,nodev,size=${inputs.bootSizes.runSize} 0 0
        tmpfs /dev/shm tmpfs mode=1777,nosuid,nodev,size=${inputs.bootSizes.devShmSize} 0 0
      '';

      # User-defined filesystem entries
      userFstab = builtins.concatStringsSep "\n" (builtins.map fstabLine fileSystems);

      # Swap entries from swap.devices
      swapDevices = builtins.filter (d: (d.enable or true)) (inputs.swapDev.devices or [ ]);
      swapFstab = builtins.concatStringsSep "\n" (
        builtins.map (
          dev:
          let
            device = if (dev.label or null) != null then "/dev/disk/by-label/${dev.label}" else dev.device;
          in
          "${device} none swap ${builtins.concatStringsSep "," (dev.options or [ "defaults" ])} 0 0"
        ) swapDevices
      );
    in
    {
      # Generate /etc/fstab with both special and user-defined filesystems
      environment.etc."fstab".text = ''
        # /etc/fstab: static filesystem configuration
        # Generated by ekaos

        ${defaultFstab}
        ${
          if userFstab != "" then
            ''
              # User-defined filesystems
              ${userFstab}
            ''
          else
            ""
        }
        ${
          if options.tmp.useTmpfs then
            ''
              # /tmp as tmpfs
              tmpfs /tmp tmpfs mode=1777,nosuid,nodev,size=${options.tmp.tmpfsSize} 0 0
            ''
          else
            ""
        }
        ${
          if swapFstab != "" then
            ''
              # Swap devices
              ${swapFstab}
            ''
          else
            ""
        }
      '';

      # Mount user-defined filesystems and handle /tmp during activation
      system.activationScripts.filesystems = {
        deps = [ "etc" ];
        text = ''
          # Mount any user-defined filesystems not already mounted
          ${builtins.concatStringsSep "\n" (
            builtins.map (
              fs:
              if !(builtins.elem fs.fsType specialFSTypes) then
                ''
                  if ! mountpoint -q ${escapeShellArg fs.mountPoint} 2>/dev/null; then
                    mkdir -p ${escapeShellArg fs.mountPoint}
                    echo "Mounting ${fs.mountPoint}..."
                    mount ${escapeShellArg fs.mountPoint} 2>/dev/null || true
                  fi
                ''
              else
                ""
            ) fileSystems
          )}

          ${
            if (!options.tmp.useTmpfs && options.tmp.cleanOnBoot) then
              ''
                # Clean /tmp on boot
                echo "Cleaning /tmp..."
                find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
              ''
            else
              ""
          }
        '';
      };
    };
}
