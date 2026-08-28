# Nix daemon configuration
# Generates /etc/nix/nix.conf
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.nix;

  # Format a nix.conf value
  formatValue =
    v:
    if isBool v then
      (if v then "true" else "false")
    else if isList v then
      concatStringsSep " " (map toString v)
    else
      toString v;

  # Generate nix.conf from settings
  nixConf = concatStringsSep "\n" (
    mapAttrsToList (name: value: "${name} = ${formatValue value}") cfg.settings
  );

  # Generate nix-path setting
  nixPathConf = optionalString (cfg.nixPath != [ ]) (
    "nix-path = ${concatStringsSep ":" cfg.nixPath}"
  );

in

{
  options.nix = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable Nix. Disabling this makes the system
        very hard to modify, only do so if you know what you're doing.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.nix;
      defaultText = literalExpression "pkgs.nix";
      description = ''
        The Nix package to use for the daemon and CLI tools.

        All modules should reference config.nix.package instead of pkgs.nix.
      '';
    };

    settings = mkOption {
      type = types.attrsOf (
        types.oneOf [
          types.bool
          types.int
          types.str
          types.path
          (types.listOf types.str)
        ]
      );
      default = { };
      example = literalExpression ''
        {
          max-jobs = 4;
          cores = 0;
          sandbox = true;
          auto-optimise-store = true;
          substituters = [ "https://cache.nixos.org" ];
          trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
        }
      '';
      description = ''
        Nix daemon settings written to /etc/nix/nix.conf.
        See nix.conf(5) for available options.
      '';
    };

    extraOptions = mkOption {
      type = types.lines;
      default = "";
      example = ''
        keep-outputs = true
        keep-derivations = true
      '';
      description = ''
        Additional text appended verbatim to /etc/nix/nix.conf.

        Use this for options not covered by nix.settings.
      '';
    };

    nixPath = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
        "/nix/var/nix/profiles/per-user/root/channels"
      ];
      description = ''
        Default Nix expression search path entries.

        Rendered as the nix-path setting in nix.conf.
      '';
    };

    nrBuildUsers = mkOption {
      type = types.int;
      default = 32;
      description = ''
        Number of nixbld user accounts to create for secure concurrent builds.

        Each parallel build runs as a separate nixbld user.
      '';
    };

    gc = {
      automatic = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to run nix garbage collection automatically.";
      };

      dates = mkOption {
        type = types.str;
        default = "weekly";
        example = "03:15";
        description = ''
          Schedule for automatic garbage collection.

          Accepts calendar specs like "daily", "weekly", "monthly",
          or systemd OnCalendar syntax like "03:15", "Mon..Fri 02:00".
        '';
      };

      options = mkOption {
        type = types.str;
        default = "--delete-older-than 30d";
        example = "--max-freed 1G";
        description = "Options passed to nix-collect-garbage.";
      };

      persistent = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to catch up on missed GC runs after sleep/shutdown.";
      };

      randomizedDelay = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 1800;
        description = "Random delay in seconds before GC to prevent thundering herd.";
      };
    };

    optimise = {
      automatic = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to automatically optimise the Nix store (deduplicate via hard links).
        '';
      };

      dates = mkOption {
        type = types.str;
        default = "03:45";
        example = "weekly";
        description = "Schedule for automatic store optimization (calendar spec).";
      };

      persistent = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to catch up on missed optimise runs.";
      };
    };

    checkConfig = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to check that the generated nix.conf is valid
        at build time.
      '';
    };

    checkAllErrors = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether nix.conf validation checks for any kind of error.
        When false, only unknown settings are checked.
      '';
    };

    distributedBuilds = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable distributed builds to remote machines
        defined in nix.buildMachines.
      '';
    };

    buildMachines = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            hostName = mkOption {
              type = types.str;
              description = "Hostname or IP of the remote builder.";
            };

            protocol = mkOption {
              type = types.nullOr (
                types.enum [
                  "ssh"
                  "ssh-ng"
                ]
              );
              default = "ssh";
              description = "Protocol for connecting to the builder.";
            };

            system = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "x86_64-linux";
              description = "System type the builder supports (takes precedence over systems).";
            };

            systems = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = [
                "x86_64-linux"
                "aarch64-linux"
              ];
              description = "System types the builder supports.";
            };

            sshUser = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "builder";
              description = "SSH user for connecting to the builder.";
            };

            sshKey = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "/root/.ssh/builder_key";
              description = "Path to the SSH private key for the builder.";
            };

            maxJobs = mkOption {
              type = types.int;
              default = 1;
              description = "Maximum number of concurrent builds on this machine.";
            };

            speedFactor = mkOption {
              type = types.int;
              default = 1;
              description = "Speed factor for build scheduling (higher = preferred).";
            };

            mandatoryFeatures = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Features the machine must have for a build to be scheduled.";
            };

            supportedFeatures = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Features the machine supports.";
            };

            publicHostKey = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Base64-encoded public host key of the builder.";
            };
          };
        }
      );
      default = [ ];
      description = ''
        Remote machines for distributed Nix builds.

        See https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-builders
      '';
    };

    registry = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            from = mkOption {
              type = types.attrsOf types.anything;
              description = "Flake reference to rewrite.";
            };

            to = mkOption {
              type = types.attrsOf types.anything;
              description = "Flake reference to rewrite to.";
            };

            exact = mkOption {
              type = types.bool;
              default = true;
              description = "Whether 'from' must match exactly.";
            };

            flake = mkOption {
              type = types.nullOr types.anything;
              default = null;
              description = ''
                A flake input to use as the rewrite target.
                When set, 'to' is derived automatically.
              '';
            };
          };
        }
      );
      default = { };
      description = ''
        System-wide flake registry.

        Maps flake references to other flake references, allowing
        e.g. 'nixpkgs' to resolve to a specific version.
      '';
    };

    sshServe = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable serving the Nix store over SSH.

          Allows other machines to use this machine as a binary cache
          via SSH.
        '';
      };

      keys = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "SSH public keys allowed to access the Nix store.";
      };

      protocol = mkOption {
        type = types.enum [
          "ssh"
          "ssh-ng"
        ];
        default = "ssh-ng";
        description = "Nix store protocol to use for SSH serving.";
      };

      write = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to allow writing to the Nix store over SSH.";
      };
    };

    daemonCPUSchedPolicy = mkOption {
      type = types.enum [
        "other"
        "batch"
        "idle"
      ];
      default = "other";
      description = ''
        CPU scheduling policy for the Nix daemon and its child processes.

        - other: Standard scheduling
        - batch: Batch processing (non-interactive)
        - idle: Only run when nothing else needs CPU
      '';
    };

    daemonIOSchedClass = mkOption {
      type = types.enum [
        "best-effort"
        "idle"
      ];
      default = "best-effort";
      description = ''
        I/O scheduling class for the Nix daemon.

        - best-effort: Normal I/O priority
        - idle: Only do I/O when nothing else needs the disk
      '';
    };

    daemonIOSchedPriority = mkOption {
      type = types.int;
      default = 4;
      description = ''
        I/O scheduling priority for the Nix daemon (0=highest, 7=lowest).
        Only used with best-effort scheduling class.
      '';
    };

    channel = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to enable the default Nix channel.";
      };
    };
  };

  config = {
    # Default sane settings
    nix.settings = {
      max-jobs = mkDefault "auto";
      cores = mkDefault 0;
      sandbox = mkDefault true;
      experimental-features = mkDefault "nix-command flakes";
    };

    # Generate /etc/nix/nix.conf
    environment.etc."nix/nix.conf".text = ''
      # Generated by ekaos nix-daemon module
      ${nixConf}
      ${nixPathConf}
      ${optionalString (cfg.extraOptions != "") ''

        # Extra options
        ${cfg.extraOptions}
      ''}
    '';

    # Create nix directories and build users
    system.activationScripts.nix-daemon = stringAfter [ "etc" ] ''
      mkdir -p /etc/nix
      mkdir -p /nix/var/nix/profiles/per-user
      mkdir -p /nix/var/nix/gcroots/per-user

      # Ensure nixbld group exists and create build users
      ${optionalString (cfg.nrBuildUsers > 0) ''
        for i in $(seq 1 ${toString cfg.nrBuildUsers}); do
          if ! id "nixbld$i" >/dev/null 2>&1; then
            echo "Build user nixbld$i should be created by user management"
          fi
        done
      ''}
    '';

    # Build users
    users.groups.nixbld = mkIf (cfg.nrBuildUsers > 0) {
      gid = 30000;
      members = genList (i: "nixbld${toString (i + 1)}") cfg.nrBuildUsers;
    };

    users.users = mkMerge [
      (mkIf (cfg.nrBuildUsers > 0) (
        listToAttrs (
          genList (
            i:
            let
              n = i + 1;
            in
            nameValuePair "nixbld${toString n}" {
              uid = 30000 + n;
              group = "nixbld";
              description = "Nix build user ${toString n}";
              isSystemUser = true;
              homeDirectory = "/var/empty";
              shell = "/run/current-system/sw/bin/nologin";
            }
          ) cfg.nrBuildUsers
        )
      ))

      (mkIf cfg.sshServe.enable {
        nix-ssh = {
          description = "Nix SSH store user";
          isSystemUser = true;
          group = "nogroup";
          shell = "${cfg.package}/bin/nix-store --serve ${optionalString cfg.sshServe.write "--write"}";
          openssh.authorizedKeys.keys = cfg.sshServe.keys;
        };
      })
    ];

    # Generate /etc/nix/machines for distributed builds
    environment.etc."nix/machines" = mkIf (cfg.buildMachines != [ ]) {
      text = concatMapStringsSep "\n" (
        m:
        let
          systems = if m.system != null then [ m.system ] else m.systems;
          protocol = if m.protocol != null then "${m.protocol}://" else "";
          user = optionalString (m.sshUser != null) "${m.sshUser}@";
          key = optionalString (m.sshKey != null) " ${m.sshKey}";
        in
        "${protocol}${user}${m.hostName} ${concatStringsSep "," systems} ${key} ${toString m.maxJobs} ${toString m.speedFactor} ${concatStringsSep "," m.supportedFeatures} ${concatStringsSep "," m.mandatoryFeatures}"
      ) cfg.buildMachines;
    };

    nix.settings.builders = mkIf cfg.distributedBuilds (mkDefault "@/etc/nix/machines");

    # Generate flake registry
    environment.etc."nix/registry.json" = mkIf (cfg.registry != { }) {
      text = builtins.toJSON {
        version = 2;
        flakes = mapAttrsToList (
          name: entry:
          {
            inherit (entry) from to exact;
          }
          // optionalAttrs (entry.from == { }) {
            from = {
              type = "indirect";
              id = name;
            };
          }
        ) cfg.registry;
      };
    };

    # Automatic GC via timers
    timers.nix-gc = mkIf cfg.gc.automatic {
      enable = true;
      description = "Nix garbage collection";
      schedule.calendar = cfg.gc.dates;
      schedule.persistent = cfg.gc.persistent;
      schedule.randomDelay = cfg.gc.randomizedDelay;
      script = "${cfg.package}/bin/nix-collect-garbage ${cfg.gc.options}";
      user = "root";
    };

    # Automatic store optimization via timers
    timers.nix-optimise = mkIf cfg.optimise.automatic {
      enable = true;
      description = "Nix store optimization";
      schedule.calendar = cfg.optimise.dates;
      schedule.persistent = cfg.optimise.persistent;
      script = "${cfg.package}/bin/nix store optimise";
      user = "root";
    };
  };
}
