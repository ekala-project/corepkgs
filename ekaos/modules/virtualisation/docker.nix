# Adios port of ekaos/modules/virtualisation/docker.nix.
#
# Tree path: virtualisation/docker is parent.virtualisation.docker.
# Owns virtualisation.docker.* (group `docker`) and contributes the
# services.docker definition (group `service`, consumed by the
# service-manager modules) plus a timers.docker-prune entry.
# TODO(adios-cutover): impl computes services.docker command/args from
# options.package (legacy self-augmenting config write); the tree must
# merge impl outputs back (NixOS module-merge semantics). service.command
# had no legacy default (internal); no default here either (value comes
# from impl). internal/visible dropped throughout.
# TODO(adios-cutover): timers.docker-prune write targets the timers
# module's namespace (parent.tasks.timers); merged by the tree.
{ types, pkgs, ... }:

{
  options = {
    docker = {
      description = "Docker container runtime settings.";
      options = {
        enable = {
          type = types.bool;
          default = false;
          description = "Whether to enable the Docker container runtime.";
        };

        package = {
          type = types.nullOr types.derivation;
          default = pkgs.docker or null;
          description = "The Docker package to use.";
        };

        enableOnBoot = {
          type = types.bool;
          default = true;
          description = "Whether to start Docker at boot.";
        };

        storageDriver = {
          type = types.nullOr (
            types.enum "docker-storage-driver" [
              "aufs"
              "btrfs"
              "devicemapper"
              "overlay"
              "overlay2"
              "zfs"
            ]
          );
          default = null;
          description = "Storage driver for Docker. null uses Docker's default (overlay2).";
        };

        logDriver = {
          type = types.enum "docker-log-driver" [
            "none"
            "json-file"
            "syslog"
            "journald"
            "gelf"
            "fluentd"
            "awslogs"
            "splunk"
            "etwlogs"
            "gcplogs"
          ];
          default = "journald";
          description = "Default logging driver for Docker containers.";
        };

        liveRestore = {
          type = types.bool;
          default = true;
          description = "Whether containers should remain running when the daemon stops.";
        };

        extraOptions = {
          type = types.string;
          default = "";
          description = "Extra command-line options for the Docker daemon.";
        };

        extraPackages = {
          type = types.listOf types.derivation;
          default = [ ];
          description = "Extra packages available to the Docker daemon.";
        };

        autoPrune = {
          description = "Periodic pruning of unused Docker data.";
          options = {
            enable = {
              type = types.bool;
              default = false;
              description = "Whether to periodically prune unused Docker data.";
            };

            dates = {
              type = types.string;
              default = "weekly";
              description = "Schedule for Docker pruning (calendar spec).";
            };

            flags = {
              type = types.listOf types.string;
              default = [ ];
              example = [
                "--all"
                "--volumes"
              ];
              description = "Flags passed to docker system prune.";
            };
          };
        };

        rootless = {
          description = "Rootless Docker settings.";
          options = {
            enable = {
              type = types.bool;
              default = false;
              description = "Whether to enable rootless Docker.";
            };
          };
        };
      };
    };

    service = {
      description = ''
        Cross-platform service definition contributed to services.docker
        (consumed by the active service manager).
      '';
      options = {
        enable = {
          type = types.bool;
          default = false;
          description = "Whether to enable the Docker service.";
        };

        description = {
          type = types.string;
          default = "Docker Container Runtime";
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

  assertions = [
    {
      verify = { options, ... }: (!options.docker.enable) || (options.docker.package != null);
      explain = { options, ... }: "package option must be set when enabled (docker is not in core-pkgs)";
    }
  ];

  impl =
    { options, inputs }:
    if !options.docker.enable then
      { }
    else
      {
        users.groups.docker = { };

        environment.systemPackages = [ options.docker.package ] ++ options.docker.extraPackages;

        services.docker = {
          enable = true;
          command = "${options.docker.package}/bin/dockerd";
          args = [
            "--group=docker"
          ]
          ++ (
            if options.docker.storageDriver != null then
              [ "--storage-driver=${options.docker.storageDriver}" ]
            else
              [ ]
          )
          ++ [
            "--log-driver=${options.docker.logDriver}"
          ]
          ++ (if options.docker.liveRestore then [ "--live-restore" ] else [ ]);
          user = "root";
          restartPolicy = "always";
          systemd = {
            after = [
              "network.target"
              "firewall.service"
            ];
          }
          // (if options.docker.enableOnBoot then { wantedBy = [ "multi-user.target" ]; } else { });
        };
      }
      // (
        if options.docker.autoPrune.enable then
          {
            # Auto-prune timer
            timers.docker-prune = {
              enable = true;
              description = "Docker system prune";
              schedule.calendar = options.docker.autoPrune.dates;
              schedule.persistent = true;
              script = "${options.docker.package}/bin/docker system prune -f ${builtins.concatStringsSep " " options.docker.autoPrune.flags}";
              user = "root";
            };
          }
        else
          { }
      );
}
