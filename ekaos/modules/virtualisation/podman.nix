# Podman container runtime
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.virtualisation.podman;

  # Build containers storage.conf
  storageConf = pkgs.writeText "storage.conf" ''
    [storage]
    driver = "${cfg.storage.driver}"
    graphroot = "${cfg.storage.graphRoot}"
    runroot = "${cfg.storage.runRoot}"

    [storage.options]
    ${optionalString (cfg.storage.driver == "overlay") ''
      [storage.options.overlay]
      mount_program = "${pkgs.fuse-overlayfs}/bin/fuse-overlayfs"
    ''}
  '';

  # Build containers.conf
  containersConf = pkgs.writeText "containers.conf" ''
    [containers]
    log_driver = "${cfg.containers.logDriver}"

    [engine]
    runtime = "${cfg.runtime}/bin/${if cfg.runtime.pname or "" == "crun" then "crun" else "runc"}"

    [network]
    network_backend = "netavark"
    ${optionalString (pkgs ? aardvark-dns) ''
      dns_bind_port = 53
    ''}
  '';

  # Build registries.conf
  registriesConf = pkgs.writeText "registries.conf" ''
    [registries.search]
    registries = [${concatMapStringsSep ", " (r: "'${r}'") cfg.registries.search}]

    [registries.block]
    registries = [${concatMapStringsSep ", " (r: "'${r}'") cfg.registries.block}]
  '';

in

{
  options.virtualisation.podman = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable Podman, a daemonless container engine.
        Podman can run OCI containers without requiring a daemon process.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.podman;
      description = "The Podman package to use.";
    };

    runtime = mkOption {
      type = types.package;
      default = pkgs.crun;
      description = "OCI runtime for containers (crun or runc).";
    };

    dockerCompat = mkOption {
      type = types.bool;
      default = false;
      description = "Create a 'docker' alias pointing to podman.";
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
        description = "Storage driver for container images.";
      };

      graphRoot = mkOption {
        type = types.str;
        default = "/var/lib/containers/storage";
        description = "Root directory for container storage.";
      };

      runRoot = mkOption {
        type = types.str;
        default = "/run/containers/storage";
        description = "Runtime directory for temporary container data.";
      };
    };

    containers = {
      logDriver = mkOption {
        type = types.enum [
          "k8s-file"
          "journald"
          "none"
        ];
        default = "journald";
        description = "Default log driver for containers.";
      };
    };

    registries = {
      search = mkOption {
        type = types.listOf types.str;
        default = [
          "docker.io"
          "quay.io"
        ];
        description = "Container registries to search by default.";
      };

      block = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Container registries to block.";
      };
    };

    autoPrune = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Periodically prune unused containers, images, and volumes.";
      };

      schedule = mkOption {
        type = types.str;
        default = "weekly";
        description = "How often to run auto-prune.";
      };

      flags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "--all" ];
        description = "Additional flags passed to 'podman system prune'.";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      cfg.runtime
      pkgs.conmon
      pkgs.skopeo
      pkgs.slirp4netns
      pkgs.fuse-overlayfs
    ]
    ++ optional (pkgs ? netavark) pkgs.netavark
    ++ optional (pkgs ? aardvark-dns) pkgs.aardvark-dns
    ++ optional cfg.dockerCompat (
      pkgs.runCommand "podman-docker-compat" { } ''
        mkdir -p $out/bin
        ln -s ${cfg.package}/bin/podman $out/bin/docker
      ''
    );

    # Container configuration files
    environment.etc = {
      "containers/storage.conf".source = storageConf;
      "containers/containers.conf".source = containersConf;
      "containers/registries.conf".source = registriesConf;

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
    system.activationScripts.podman = stringAfter [ "etc" ] ''
      mkdir -p ${cfg.storage.graphRoot}
      mkdir -p ${cfg.storage.runRoot}
      mkdir -p /etc/containers
    '';

    # Auto-prune timer
    timers = mkIf cfg.autoPrune.enable {
      podman-prune = {
        description = "Podman system prune";
        schedule.calendar = cfg.autoPrune.schedule;
        script = ''
          ${cfg.package}/bin/podman system prune -f ${concatStringsSep " " cfg.autoPrune.flags}
        '';
      };
    };
  };
}
