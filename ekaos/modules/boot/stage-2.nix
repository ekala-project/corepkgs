# Stage-2 boot initialization
# This init script mounts filesystems, runs activation, and starts systemd
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  # The stage-2 init script
  bootStage2 = pkgs.writeScript "stage-2-init" ''
    #!${pkgs.runtimeShell}
    set -e

    echo "${config.boot.stage2Greeting}"

    # Get the system configuration path
    systemConfig="@systemConfig@"

    # Mount special filesystems if not already mounted
    specialMount() {
      local device="$1"
      local mountPoint="$2"
      local options="$3"
      local fsType="$4"

      if ! mountpoint -q "$mountPoint"; then
        mkdir -p "$mountPoint"
        mount -t "$fsType" -o "$options" "$device" "$mountPoint"
      fi
    }

    echo "Mounting special filesystems..."
    specialMount "proc" "/proc" "nosuid,noexec,nodev" "proc"
    specialMount "sysfs" "/sys" "nosuid,noexec,nodev" "sysfs"
    specialMount "devtmpfs" "/dev" "mode=0755,nosuid,size=${config.boot.devSize}" "devtmpfs"
    specialMount "devpts" "/dev/pts" "mode=0620,gid=3,nosuid,noexec" "devpts"
    specialMount "tmpfs" "/run" "mode=0755,nosuid,nodev,size=${config.boot.runSize}" "tmpfs"
    specialMount "tmpfs" "/dev/shm" "mode=1777,nosuid,nodev,size=${config.boot.devShmSize}" "tmpfs"

    # Make /nix/store a read-only bind mount if it's a regular directory
    # (it might already be a separate filesystem)
    if [ -d /nix/store ] && ! mountpoint -q /nix/store; then
      mount --bind /nix/store /nix/store
      mount -o remount,ro,bind /nix/store
    fi

    # Create essential directories
    mkdir -p /tmp /var/log /var/tmp
    chmod 1777 /tmp /var/tmp

    # Run the activation script
    echo "Running activation script..."
    if [ -x "$systemConfig/activate" ]; then
      "$systemConfig/activate"
    else
      echo "Warning: No activation script found at $systemConfig/activate"
    fi

    # Record the booted system
    mkdir -p /run
    ln -sfn "$systemConfig" /run/booted-system

    # Run post-boot commands
    ${optionalString (config.boot.postBootCommands != "") ''
      echo "Running post-boot commands..."
      ${config.boot.postBootCommands}
    ''}

    # Start systemd as PID 1
    echo "Starting systemd..."
    exec ${config.systemd.package}/lib/systemd/systemd
  '';

in

{
  options = {
    boot.postBootCommands = mkOption {
      type = types.lines;
      default = "";
      example = ''
        # Import ZFS pools
        zpool import -a
      '';
      description = ''
        Shell commands to be executed just before systemd is started.

        This is useful for one-time setup tasks that must run after
        activation but before services start.
      '';
    };

    boot.stage2Greeting = mkOption {
      type = types.str;
      default = "<<< ekaos Stage 2 >>>";
      example = "<<< My Custom System >>>";
      description = ''
        Greeting message displayed during stage 2 boot.
      '';
    };

    boot.devSize = mkOption {
      type = types.str;
      default = "5%";
      example = "32m";
      description = ''
        Size limit for the /dev tmpfs filesystem.

        Can be a percentage of RAM or an absolute size.
      '';
    };

    boot.devShmSize = mkOption {
      type = types.str;
      default = "50%";
      example = "256m";
      description = ''
        Size limit for the /dev/shm tmpfs filesystem.

        Can be a percentage of RAM or an absolute size.
      '';
    };

    boot.runSize = mkOption {
      type = types.str;
      default = "25%";
      example = "256m";
      description = ''
        Size limit for the /run tmpfs filesystem.

        Can be a percentage of RAM or an absolute size.
      '';
    };

    system.build.bootStage2 = mkOption {
      type = types.package;
      internal = true;
      description = ''
        The stage-2 init script that mounts filesystems,
        runs activation, and starts systemd.
      '';
    };
  };

  config = {
    system.build.bootStage2 = bootStage2;
  };
}
