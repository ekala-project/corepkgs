# OCI container infrastructure
# Shared configuration for Podman and Docker container runtimes
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.virtualisation.containers;
in

{
  options = {
    virtualisation.containers = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable shared OCI container infrastructure.

          This provides container storage, registries, and policy
          configuration shared between Podman and Docker.
        '';
      };

      registries = {
        search = mkOption {
          type = types.listOf types.str;
          default = [ "docker.io" ];
          description = "Default registries searched for unqualified image names.";
        };

        insecure = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Registries to access without TLS verification.";
        };

        block = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Registries to block (deny pulling from).";
        };
      };

      storage = {
        driver = mkOption {
          type = types.enum [
            "overlay"
            "vfs"
            "btrfs"
            "zfs"
          ];
          default = "overlay";
          description = "Container storage driver.";
        };

        graphRoot = mkOption {
          type = types.str;
          default = "/var/lib/containers/storage";
          description = "Root directory for container image storage.";
        };

        runRoot = mkOption {
          type = types.str;
          default = "/run/containers/storage";
          description = "Root directory for container runtime storage.";
        };
      };

      policy = mkOption {
        type = types.attrs;
        default = {
          default = [ { type = "insecureAcceptAnything"; } ];
        };
        description = "Container signature verification policy.";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.etc."containers/registries.conf".text = ''
      [registries.search]
      registries = [${concatMapStringsSep ", " (r: "\"${r}\"") cfg.registries.search}]

      [registries.insecure]
      registries = [${concatMapStringsSep ", " (r: "\"${r}\"") cfg.registries.insecure}]

      [registries.block]
      registries = [${concatMapStringsSep ", " (r: "\"${r}\"") cfg.registries.block}]
    '';

    environment.etc."containers/storage.conf".text = ''
      [storage]
      driver = "${cfg.storage.driver}"
      graphroot = "${cfg.storage.graphRoot}"
      runroot = "${cfg.storage.runRoot}"
    '';

    environment.etc."containers/policy.json".text = builtins.toJSON cfg.policy;

    system.activationScripts.containers = stringAfter [ "etc" ] ''
      mkdir -p ${cfg.storage.graphRoot}
      mkdir -p ${cfg.storage.runRoot}
    '';
  };
}
