# Stage-2 boot initialization
# This init script mounts filesystems, runs activation, and starts systemd
{ config, lib, pkgs, ... }:

with lib;

let
  # The stage-2 init script
  bootStage2 = pkgs.writeScript "stage-2-init" ''
    #!${pkgs.runtimeShell}
    set -e

    echo "ekaos stage-2 init starting..."

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
    specialMount "devtmpfs" "/dev" "mode=0755,nosuid" "devtmpfs"
    specialMount "devpts" "/dev/pts" "mode=0620,gid=3,nosuid,noexec" "devpts"
    specialMount "tmpfs" "/run" "mode=0755,nosuid,nodev,size=25%" "tmpfs"
    specialMount "tmpfs" "/dev/shm" "mode=1777,nosuid,nodev" "tmpfs"

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

    # Start systemd as PID 1
    echo "Starting systemd..."
    exec ${config.systemd.package}/lib/systemd/systemd
  '';

in

{
  options = {
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
