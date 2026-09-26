# Adios port of ekaos/modules/virtualisation/containers.nix.
#
# Tree path: virtualisation/containers is parent.virtualisation.containers.
# Shared OCI container infrastructure (storage, registries, policy)
# for Podman and Docker. Self-contained; no cross-module reads.
{ types, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable shared OCI container infrastructure.

        This provides container storage, registries, and policy
        configuration shared between Podman and Docker.
      '';
    };

    registries = {
      description = "Container registry configuration.";
      options = {
        search = {
          type = types.listOf types.string;
          default = [ "docker.io" ];
          description = "Default registries searched for unqualified image names.";
        };

        insecure = {
          type = types.listOf types.string;
          default = [ ];
          description = "Registries to access without TLS verification.";
        };

        block = {
          type = types.listOf types.string;
          default = [ ];
          description = "Registries to block (deny pulling from).";
        };
      };
    };

    storage = {
      description = "Container image storage configuration.";
      options = {
        driver = {
          type = types.enum "container-storage-driver" [
            "overlay"
            "vfs"
            "btrfs"
            "zfs"
          ];
          default = "overlay";
          description = "Container storage driver.";
        };

        graphRoot = {
          type = types.string;
          default = "/var/lib/containers/storage";
          description = "Root directory for container image storage.";
        };

        runRoot = {
          type = types.string;
          default = "/run/containers/storage";
          description = "Root directory for container runtime storage.";
        };
      };
    };

    policy = {
      type = types.attrs;
      default = {
        default = [ { type = "insecureAcceptAnything"; } ];
      };
      description = "Container signature verification policy.";
    };
  };

  impl =
    { options, inputs }:
    if !options.enable then
      { }
    else
      {
        environment.etc."containers/registries.conf".text = ''
          [registries.search]
          registries = [${
            builtins.concatStringsSep ", " (builtins.map (r: "\"${r}\"") options.registries.search)
          }]

          [registries.insecure]
          registries = [${
            builtins.concatStringsSep ", " (builtins.map (r: "\"${r}\"") options.registries.insecure)
          }]

          [registries.block]
          registries = [${
            builtins.concatStringsSep ", " (builtins.map (r: "\"${r}\"") options.registries.block)
          }]
        '';

        environment.etc."containers/storage.conf".text = ''
          [storage]
          driver = "${options.storage.driver}"
          graphroot = "${options.storage.graphRoot}"
          runroot = "${options.storage.runRoot}"
        '';

        environment.etc."containers/policy.json".text = builtins.toJSON options.policy;

        system.activationScripts.containers = {
          deps = [ "etc" ];
          text = ''
            mkdir -p ${options.storage.graphRoot}
            mkdir -p ${options.storage.runRoot}
          '';
        };
      };
}
