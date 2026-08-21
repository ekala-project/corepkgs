# libvirtd — virtualization management daemon
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.virtualisation.libvirtd;
in

{
  options = {
    virtualisation.libvirtd = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable libvirtd for managing VMs (KVM/QEMU).
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.libvirt or (throw "libvirt package not available");
        defaultText = literalExpression "pkgs.libvirt";
        description = "The libvirt package to use.";
      };

      enableKVM = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable KVM hardware acceleration.";
      };

      allowedBridges = mkOption {
        type = types.listOf types.str;
        default = [ "virbr0" ];
        description = "Bridge interfaces libvirt is allowed to use.";
      };

      onBoot = mkOption {
        type = types.enum [
          "ignore"
          "start"
        ];
        default = "start";
        description = "What to do with running VMs when the host boots.";
      };

      onShutdown = mkOption {
        type = types.enum [
          "shutdown"
          "suspend"
        ];
        default = "suspend";
        description = "What to do with running VMs when the host shuts down.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Additional lines appended to libvirtd.conf.";
      };
    };

    services.libvirtd = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the libvirtd service.";
      };
      description = mkOption {
        type = types.str;
        default = "Libvirt Virtualization Daemon";
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
        default = "always";
        description = "Restart policy.";
      };
      systemd = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = "Systemd-specific options.";
      };
    };
  };

  config = mkIf cfg.enable {
    boot.kernelModules = mkIf cfg.enableKVM [
      "kvm"
      "kvm-intel"
      "kvm-amd"
    ];

    users.groups.libvirt = { };

    environment.systemPackages = [ cfg.package ];

    services.libvirtd = {
      enable = true;
      command = "${cfg.package}/bin/libvirtd";
      args = [ "--daemon" ];
      user = "root";
      restartPolicy = "always";
      systemd = {
        after = [
          "network.target"
          "dbus.service"
        ];
        wantedBy = [ "multi-user.target" ];
      };
    };

    services.dbus.packages = [ cfg.package ];

    system.activationScripts.libvirtd = stringAfter [ "etc" "users" ] ''
      mkdir -p /var/lib/libvirt/qemu
      mkdir -p /var/log/libvirt
      mkdir -p /run/libvirt
    '';
  };
}
