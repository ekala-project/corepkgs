# Adios port of ekaos/modules/virtualisation/podman.nix.
#
# Tree path: virtualisation/podman is parent.virtualisation.podman.
# Self-contained; no cross-module reads. Config-file derivations and the
# docker-compat shim are built by top-level-let functions closing over
# pkgs (impl only sees { options, inputs }).
# TODO(adios-cutover): timers.podman-prune write targets the timers
# module's namespace (parent.tasks.timers); merged by the tree. The entry
# keeps its legacy shape (no `enable` key — legacy commonTimerOptions
# defaulted it to false).
{ types, pkgs, ... }:

let
  # Build containers storage.conf
  mkStorageConf =
    {
      driver,
      graphRoot,
      runRoot,
    }:
    pkgs.writeText "storage.conf" ''
      [storage]
      driver = "${driver}"
      graphroot = "${graphRoot}"
      runroot = "${runRoot}"

      [storage.options]
      ${
        if driver == "overlay" then
          ''
            [storage.options.overlay]
            mount_program = "${pkgs.fuse-overlayfs}/bin/fuse-overlayfs"
          ''
        else
          ""
      }
    '';

  # Build containers.conf
  mkContainersConf =
    { logDriver, runtime }:
    pkgs.writeText "containers.conf" ''
      [containers]
      log_driver = "${logDriver}"

      [engine]
      runtime = "${runtime}/bin/${if runtime.pname or "" == "crun" then "crun" else "runc"}"

      [network]
      network_backend = "netavark"
      ${
        if (pkgs ? aardvark-dns) then
          ''
            dns_bind_port = 53
          ''
        else
          ""
      }
    '';

  # Build registries.conf
  mkRegistriesConf =
    { search, block }:
    pkgs.writeText "registries.conf" ''
      [registries.search]
      registries = [${builtins.concatStringsSep ", " (builtins.map (r: "'${r}'") search)}]

      [registries.block]
      registries = [${builtins.concatStringsSep ", " (builtins.map (r: "'${r}'") block)}]
    '';

  mkDockerCompat =
    package:
    pkgs.runCommand "podman-docker-compat" { } ''
      mkdir -p $out/bin
      ln -s ${package}/bin/podman $out/bin/docker
    '';
in

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Enable Podman, a daemonless container engine.
        Podman can run OCI containers without requiring a daemon process.
      '';
    };

    package = {
      type = types.derivation;
      default = pkgs.podman;
      description = "The Podman package to use.";
    };

    runtime = {
      type = types.derivation;
      default = pkgs.crun;
      description = "OCI runtime for containers (crun or runc).";
    };

    dockerCompat = {
      type = types.bool;
      default = false;
      description = "Create a 'docker' alias pointing to podman.";
    };

    storage = {
      description = "Container image storage configuration.";
      options = {
        driver = {
          type = types.enum "podman-storage-driver" [
            "overlay"
            "vfs"
            "btrfs"
            "zfs"
          ];
          default = "overlay";
          description = "Storage driver for container images.";
        };

        graphRoot = {
          type = types.string;
          default = "/var/lib/containers/storage";
          description = "Root directory for container storage.";
        };

        runRoot = {
          type = types.string;
          default = "/run/containers/storage";
          description = "Runtime directory for temporary container data.";
        };
      };
    };

    containers = {
      description = "Container engine behaviour.";
      options = {
        logDriver = {
          type = types.enum "podman-log-driver" [
            "k8s-file"
            "journald"
            "none"
          ];
          default = "journald";
          description = "Default log driver for containers.";
        };
      };
    };

    registries = {
      description = "Container registry configuration.";
      options = {
        search = {
          type = types.listOf types.string;
          default = [
            "docker.io"
            "quay.io"
          ];
          description = "Container registries to search by default.";
        };

        block = {
          type = types.listOf types.string;
          default = [ ];
          description = "Container registries to block.";
        };
      };
    };

    autoPrune = {
      description = "Periodic pruning of unused podman data.";
      options = {
        enable = {
          type = types.bool;
          default = false;
          description = "Periodically prune unused containers, images, and volumes.";
        };

        schedule = {
          type = types.string;
          default = "weekly";
          description = "How often to run auto-prune.";
        };

        flags = {
          type = types.listOf types.string;
          default = [ ];
          example = [ "--all" ];
          description = "Additional flags passed to 'podman system prune'.";
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
        environment.systemPackages = [
          options.package
          options.runtime
          pkgs.conmon
          pkgs.skopeo
          pkgs.slirp4netns
          pkgs.fuse-overlayfs
        ]
        ++ (if (pkgs ? netavark) then [ pkgs.netavark ] else [ ])
        ++ (if (pkgs ? aardvark-dns) then [ pkgs.aardvark-dns ] else [ ])
        ++ (if options.dockerCompat then [ (mkDockerCompat options.package) ] else [ ]);

        # Container configuration files
        environment.etc = {
          "containers/storage.conf".source = mkStorageConf {
            inherit (options.storage) driver graphRoot runRoot;
          };
          "containers/containers.conf".source = mkContainersConf {
            logDriver = options.containers.logDriver;
            runtime = options.runtime;
          };
          "containers/registries.conf".source = mkRegistriesConf {
            inherit (options.registries) search block;
          };

          # Policy: allow all images by default
          "containers/policy.json".text = builtins.toJSON {
            default = [
              {
                type = "insecureAcceptAnything";
              }
            ];
          };
        };

        # Enable kernel features
        boot.kernelModules = [
          "overlay"
          "br_netfilter"
        ];

        # Create required directories
        system.activationScripts.podman = {
          deps = [ "etc" ];
          text = ''
            mkdir -p ${options.storage.graphRoot}
            mkdir -p ${options.storage.runRoot}
            mkdir -p /etc/containers
          '';
        };
      }
      // (
        if options.autoPrune.enable then
          {
            # Auto-prune timer
            timers.podman-prune = {
              description = "Podman system prune";
              schedule.calendar = options.autoPrune.schedule;
              script = ''
                ${options.package}/bin/podman system prune -f ${builtins.concatStringsSep " " options.autoPrune.flags}
              '';
            };
          }
        else
          { }
      );
}
