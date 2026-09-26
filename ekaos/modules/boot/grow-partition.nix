# Adios port of ekaos/modules/boot/grow-partition.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:

{
  options = {
    # Legacy path: boot.growPartition.
    growPartition = {
      type = types.bool;
      default = false;
      description = ''
        Whether to grow the root partition on boot to fill available disk space.

        Useful for cloud/VM images where the disk may be larger than the
        initial partition layout. Requires cloud-utils for growpart and
        the appropriate filesystem resize tool (resize2fs, xfs_growfs, etc.).
      '';
    };

    # Legacy path: services.grow-partition.enable.
    enable = {
      type = types.bool;
      default = false;
      description = "Whether to enable the grow-partition service.";
    };

    # Legacy path: services.grow-partition.description.
    description = {
      type = types.string;
      default = "Grow Root Partition";
      description = "Service description.";
    };

    # Legacy paths services.grow-partition.command / .args were internal
    # options always set by config; they are folded into impl below.

    # Legacy path: services.grow-partition.user.
    user = {
      type = types.string;
      default = "root";
      description = "User to run service as.";
    };

    # Legacy path: services.grow-partition.restartPolicy.
    restartPolicy = {
      type = types.string;
      default = "never";
      description = "Restart policy.";
    };

    # Legacy path: services.grow-partition.systemd.
    systemd = {
      type = types.attrsOf types.any;
      default = { };
      description = "Systemd-specific options.";
    };
  };

  impl =
    { options, ... }:
    if !options.growPartition then
      { }
    else
      {
        # Note: legacy config hardcodes the service definition below and does
        # not consume the services.grow-partition.* options (same here).
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
