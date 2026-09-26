# Adios port of ekaos/modules/virtualisation/qemu-guest-agent.nix.
#
# Tree path: virtualisation/qemu-guest-agent is
# parent.virtualisation."qemu-guest-agent".
# Owns services.qemu-guest-agent.* (consumed by the service-manager
# modules). Self-contained; no cross-module reads.
# TODO(adios-cutover): impl computes command/args/user/restartPolicy/
# systemd (legacy self-augmenting config write); the tree must merge impl
# outputs back (NixOS module-merge semantics). command had no legacy
# default (internal); no default here either. internal dropped.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable the QEMU guest agent.

        The guest agent provides host-guest communication for QEMU/KVM
        virtual machines, enabling graceful shutdown, filesystem freeze/thaw
        for consistent snapshots, and network information reporting.
      '';
    };

    description = {
      type = types.string;
      default = "QEMU Guest Agent";
      description = "Service description.";
    };

    command = {
      type = types.string;
      description = "Command to run (set automatically by impl).";
    };

    args = {
      type = types.listOf types.string;
      default = [ ];
      description = "Command arguments (set automatically by impl).";
    };

    user = {
      type = types.string;
      default = "root";
      description = "User to run guest agent as.";
    };

    restartPolicy = {
      type = types.string;
      default = "always";
      description = "Restart policy.";
    };

    systemd = {
      type = types.attrsOf types.any;
      default = { };
      description = "Systemd-specific options.";
    };

    package = {
      type = types.derivation;
      default = pkgs.qemu;
      description = "QEMU package providing the guest agent.";
    };
  };

  impl =
    { options, inputs }:
    if !options.enable then
      { }
    else
      {
        services.qemu-guest-agent = {
          command = "${options.package}/bin/qemu-ga";
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

        environment.systemPackages = [ options.package ];
      };
}
