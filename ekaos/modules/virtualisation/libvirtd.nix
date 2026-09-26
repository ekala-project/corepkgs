# Adios port of ekaos/modules/virtualisation/libvirtd.nix.
#
# Tree path: virtualisation/libvirtd is parent.virtualisation.libvirtd.
# Owns virtualisation.libvirtd.* and contributes the services.libvirtd
# definition (group `service`, consumed by the service-manager modules).
# TODO(adios-cutover): impl computes services.libvirtd command/args
# (legacy self-augmenting config write); the tree must merge impl outputs
# back (NixOS module-merge semantics). service.command had no legacy
# default (internal); no default here either. internal dropped.
# TODO(adios-cutover): onBoot/onShutdown/allowedBridges/extraConfig are
# kept for shape parity but have no consumer in impl (same as legacy).
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Whether to enable libvirtd for managing VMs (KVM/QEMU).";
    };

    package = {
      type = types.derivation;
      default = pkgs.libvirt or (throw "libvirt package not available");
      description = "The libvirt package to use.";
    };

    enableKVM = {
      type = types.bool;
      default = true;
      description = "Whether to enable KVM hardware acceleration.";
    };

    allowedBridges = {
      type = types.listOf types.string;
      default = [ "virbr0" ];
      description = "Bridge interfaces libvirt is allowed to use.";
    };

    onBoot = {
      type = types.enum "libvirt-on-boot" [
        "ignore"
        "start"
      ];
      default = "start";
      description = "What to do with running VMs when the host boots.";
    };

    onShutdown = {
      type = types.enum "libvirt-on-shutdown" [
        "shutdown"
        "suspend"
      ];
      default = "suspend";
      description = "What to do with running VMs when the host shuts down.";
    };

    extraConfig = {
      type = types.string;
      default = "";
      description = "Additional lines appended to libvirtd.conf.";
    };

    service = {
      description = ''
        Cross-platform service definition contributed to services.libvirtd
        (consumed by the active service manager).
      '';
      options = {
        enable = {
          type = types.bool;
          default = false;
          description = "Whether to enable the libvirtd service.";
        };

        description = {
          type = types.string;
          default = "Libvirt Virtualization Daemon";
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
          description = "User to run service as.";
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
      };
    };
  };

  impl =
    { options, inputs }:
    if !options.enable then
      { }
    else
      {
        boot.kernelModules =
          if options.enableKVM then
            [
              "kvm"
              "kvm-intel"
              "kvm-amd"
            ]
          else
            [ ];

        users.groups.libvirt = { };

        environment.systemPackages = [ options.package ];

        services.libvirtd = {
          enable = true;
          command = "${options.package}/bin/libvirtd";
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

        services.dbus.packages = [ options.package ];

        system.activationScripts.libvirtd = {
          deps = [
            "etc"
            "users"
          ];
          text = ''
            mkdir -p /var/lib/libvirt/qemu
            mkdir -p /var/log/libvirt
            mkdir -p /run/libvirt
          '';
        };
      };
}
