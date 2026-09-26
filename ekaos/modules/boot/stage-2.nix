# Adios port of ekaos/modules/boot/stage-2.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:

let
  # The stage-2 init script. Shared by the `bootStage2` option (so adios
  # inputs can read it) and by impl (for the merged config fragment).
  buildStage2Script =
    {
      options,
      inputs ? { },
    }:
    pkgs.writeScript "stage-2-init" ''
      #!${pkgs.runtimeShell}
      set -e

      echo "${options.stage2Greeting}"

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
      specialMount "devtmpfs" "/dev" "mode=0755,nosuid,size=${options.devSize}" "devtmpfs"
      specialMount "devpts" "/dev/pts" "mode=0620,gid=3,nosuid,noexec" "devpts"
      specialMount "tmpfs" "/run" "mode=0755,nosuid,nodev,size=${options.runSize}" "tmpfs"
      specialMount "tmpfs" "/dev/shm" "mode=1777,nosuid,nodev,size=${options.devShmSize}" "tmpfs"

      # Make /nix/store a bind mount with configured options
      if [ -d /nix/store ] && ! mountpoint -q /nix/store; then
        mount --bind /nix/store /nix/store
        mount -o remount,bind,${builtins.concatStringsSep "," options.nixStoreMountOpts} /nix/store
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
      ${
        if options.postBootCommands != "" then
          ''
            echo "Running post-boot commands..."
            ${options.postBootCommands}
          ''
        else
          ""
      }

      # Start systemd as PID 1
      echo "Starting systemd..."
      ${
        if options.extraSystemdUnitPaths != [ ] then
          ''
            export SYSTEMD_UNIT_PATH="''${SYSTEMD_UNIT_PATH:+$SYSTEMD_UNIT_PATH:}${builtins.concatStringsSep ":" options.extraSystemdUnitPaths}"
          ''
        else
          ""
      }
      exec ${(inputs.systemd.systemd.package or pkgs.systemd)}/lib/systemd/systemd
    '';
in

{
  options = {
    # Legacy path: boot.postBootCommands.
    postBootCommands = {
      type = types.string;
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

    # Legacy path: boot.stage2Greeting.
    stage2Greeting = {
      type = types.string;
      default = "<<< ekaos Stage 2 >>>";
      example = "<<< My Custom System >>>";
      description = ''
        Greeting message displayed during stage 2 boot.
      '';
    };

    # Legacy path: boot.devSize.
    devSize = {
      type = types.string;
      default = "5%";
      example = "32m";
      description = ''
        Size limit for the /dev tmpfs filesystem.

        Can be a percentage of RAM or an absolute size.
      '';
    };

    # Legacy path: boot.devShmSize.
    devShmSize = {
      type = types.string;
      default = "50%";
      example = "256m";
      description = ''
        Size limit for the /dev/shm tmpfs filesystem.

        Can be a percentage of RAM or an absolute size.
      '';
    };

    # Legacy path: boot.runSize.
    runSize = {
      type = types.string;
      default = "25%";
      example = "256m";
      description = ''
        Size limit for the /run tmpfs filesystem.

        Can be a percentage of RAM or an absolute size.
      '';
    };

    # Legacy path: boot.nixStoreMountOpts.
    nixStoreMountOpts = {
      type = types.listOf types.string;
      default = [
        "ro"
        "nodev"
        "nosuid"
      ];
      description = ''
        Mount options for the /nix/store bind mount.

        "ro" enforces immutability of the Nix store.
        The store daemon undoes the bind mount when it needs to write.
      '';
    };

    # Legacy path: boot.extraSystemdUnitPaths.
    extraSystemdUnitPaths = {
      type = types.listOf types.string;
      default = [ ];
      description = ''
        Additional paths appended to the SYSTEMD_UNIT_PATH environment
        variable that can contain mutable unit files.
      '';
    };

    # Exposed as an option (not only in impl) so system/toplevel can consume
    # it through an adios input: inputs see sibling OPTIONS, never impl
    # results.
    bootStage2 = {
      type = types.derivation;
      defaultFunc = { options, inputs }: buildStage2Script { inherit options inputs; };
      description = ''
        The stage-2 init script.

        Read-only output; value comes from the defaultFunc.
      '';
    };
  };

  inputs = {
    # TODO(adios-cutover): provides systemd.package (defined in
    # ekaos/modules/system/toplevel.nix); flat leaf name pending the
    # system/toplevel port — full legacy path used below.
    systemd.from = { root }: root.system.toplevel;
  };

  impl =
    { options, inputs }:
    {
      # Legacy internal option system.build.bootStage2.
      system.build.bootStage2 = buildStage2Script { inherit options inputs; };
    };
}
