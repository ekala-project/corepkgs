# QEMU guest agent
# Enables host-guest communication for VMs (graceful shutdown, filesystem
# freeze/thaw, network info reporting)
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.qemu-guest-agent;

in

{
  options.services.qemu-guest-agent = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable the QEMU guest agent.

        The guest agent provides host-guest communication for QEMU/KVM
        virtual machines, enabling graceful shutdown, filesystem freeze/thaw
        for consistent snapshots, and network information reporting.
      '';
    };

    description = mkOption {
      type = types.str;
      default = "QEMU Guest Agent";
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
      description = "User to run guest agent as.";
    };

    restartPolicy = mkOption {
      type = types.str;
      default = "always";
      description = "Restart policy.";
    };

    systemd = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Systemd-specific options.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.qemu;
      description = "QEMU package providing the guest agent.";
    };
  };

  config = mkIf cfg.enable {
    services.qemu-guest-agent = {
      command = "${cfg.package}/bin/qemu-ga";
      args = [
        "--daemonize"
        "--method"
        "virtio-serial"
        "--path"
        "/dev/virtio-ports/org.qemu.guest_agent.0"
      ];
      user = "root";
      restartPolicy = "always";

      systemd = {
        after = [ "local-fs.target" ];
        wantedBy = [ "multi-user.target" ];
      };
    };

    environment.systemPackages = [ cfg.package ];
  };
}
