# Docker container runtime
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.virtualisation.docker;
in

{
  options = {
    virtualisation.docker = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the Docker container runtime.";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.docker or (throw "docker package not available");
        defaultText = literalExpression "pkgs.docker";
        description = "The Docker package to use.";
      };

      enableOnBoot = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to start Docker at boot.";
      };

      storageDriver = mkOption {
        type = types.nullOr (
          types.enum [
            "aufs"
            "btrfs"
            "devicemapper"
            "overlay"
            "overlay2"
            "zfs"
          ]
        );
        default = null;
        description = ''
          Storage driver for Docker. null uses Docker's default (overlay2).
        '';
      };

      logDriver = mkOption {
        type = types.enum [
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

      liveRestore = mkOption {
        type = types.bool;
        default = true;
        description = "Whether containers should remain running when the daemon stops.";
      };

      extraOptions = mkOption {
        type = types.lines;
        default = "";
        description = "Extra command-line options for the Docker daemon.";
      };

      extraPackages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        description = "Extra packages available to the Docker daemon.";
      };

      autoPrune = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to periodically prune unused Docker data.";
        };

        dates = mkOption {
          type = types.str;
          default = "weekly";
          description = "Schedule for Docker pruning (calendar spec).";
        };

        flags = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [
            "--all"
            "--volumes"
          ];
          description = "Flags passed to docker system prune.";
        };
      };

      rootless = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to enable rootless Docker.";
        };
      };
    };

    services.docker = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the Docker service.";
      };
      description = mkOption {
        type = types.str;
        default = "Docker Container Runtime";
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
    users.groups.docker = { };

    environment.systemPackages = [ cfg.package ] ++ cfg.extraPackages;

    services.docker = {
      enable = true;
      command = "${cfg.package}/bin/dockerd";
      args = [
        "--group=docker"
      ]
      ++ optional (cfg.storageDriver != null) "--storage-driver=${cfg.storageDriver}"
      ++ [
        "--log-driver=${cfg.logDriver}"
      ]
      ++ optional cfg.liveRestore "--live-restore";
      user = "root";
      restartPolicy = "always";
      systemd = {
        after = [
          "network.target"
          "firewall.service"
        ];
        wantedBy = mkIf cfg.enableOnBoot [ "multi-user.target" ];
      };
    };

    # Auto-prune timer
    timers.docker-prune = mkIf cfg.autoPrune.enable {
      enable = true;
      description = "Docker system prune";
      schedule.calendar = cfg.autoPrune.dates;
      schedule.persistent = true;
      script = "${cfg.package}/bin/docker system prune -f ${concatStringsSep " " cfg.autoPrune.flags}";
      user = "root";
    };
  };
}
