# Automatic root partition growing
# Expands the root partition to fill available disk space on boot
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.boot.growPartition;
in

{
  options = {
    boot.growPartition = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to grow the root partition on boot to fill available disk space.

        Useful for cloud/VM images where the disk may be larger than the
        initial partition layout. Requires cloud-utils for growpart and
        the appropriate filesystem resize tool (resize2fs, xfs_growfs, etc.).
      '';
    };

    services.grow-partition = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the grow-partition service.";
      };

      description = mkOption {
        type = types.str;
        default = "Grow Root Partition";
        description = "Service description.";
      };

      command = mkOption {
        type = types.str;
        internal = true;
        description = "Command to run (set automatically).";
      };

      args = mkOption {
        type = types.listOf types.str;
        internal = true;
        default = [ ];
        description = "Command arguments (set automatically).";
      };

      user = mkOption {
        type = types.str;
        default = "root";
        description = "User to run service as.";
      };

      restartPolicy = mkOption {
        type = types.str;
        default = "never";
        description = "Restart policy.";
      };

      systemd = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Systemd-specific options.";
      };
    };
  };

  config = mkIf cfg {
    services.grow-partition = {
      enable = true;
      description = "Grow Root Partition";
      command = "${pkgs.runtimeShell}";
      args = [
        "-c"
        ''
          set -eu
          ROOT_DEV=$(findmnt -n -o SOURCE /)
          # Extract the disk and partition number
          DISK=$(lsblk -no PKNAME "$ROOT_DEV" | head -1)
          PARTNUM=$(cat /sys/class/block/$(basename "$ROOT_DEV")/partition 2>/dev/null || echo "")
          if [ -n "$DISK" ] && [ -n "$PARTNUM" ]; then
            echo "Growing partition $PARTNUM on /dev/$DISK..."
            ${pkgs.cloud-utils or pkgs.busybox}/bin/growpart "/dev/$DISK" "$PARTNUM" || true
            # Resize the filesystem
            FSTYPE=$(findmnt -n -o FSTYPE /)
            case "$FSTYPE" in
              ext*) resize2fs "$ROOT_DEV" ;;
              xfs) xfs_growfs / ;;
              btrfs) btrfs filesystem resize max / ;;
              *) echo "Cannot resize filesystem type: $FSTYPE" ;;
            esac
          fi
        ''
      ];
      user = "root";
      restartPolicy = "never";
      systemd = {
        wantedBy = [ "multi-user.target" ];
        before = [ "multi-user.target" ];
        serviceConfig.Type = "oneshot";
      };
    };
  };
}
