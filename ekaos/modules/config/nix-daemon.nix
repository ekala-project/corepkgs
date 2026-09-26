# Adios port of ekaos/modules/config/nix-daemon.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
# Generates /etc/nix/nix.conf
{
  types,
  lib,
  pkgs,
  ...
}:

{
  options = {
    enable = {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable Nix. Disabling this makes the system
        very hard to modify, only do so if you know what you're doing.
      '';
    };

    package = {
      type = types.derivation;
      default = pkgs.nix;
      description = ''
        The Nix package to use for the daemon and CLI tools.

        All modules should reference config.nix.package instead of pkgs.nix.
      '';
    };

    settings = {
      type = types.attrsOf (
        types.union [
          types.bool
          types.int
          types.string
          types.pathLike
          (types.listOf types.string)
        ]
      );
      default = { };
      example = {
        max-jobs = 4;
        cores = 0;
        sandbox = true;
        auto-optimise-store = true;
        substituters = [ "https://cache.nixos.org" ];
        trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
      };
      description = ''
        Nix daemon settings written to /etc/nix/nix.conf.
        See nix.conf(5) for available options.
      '';
    };

    extraOptions = {
      type = types.string;
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

    nixPath = {
      type = types.listOf types.string;
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

    nrBuildUsers = {
      type = types.int;
      default = 32;
      description = ''
        Number of nixbld user accounts to create for secure concurrent builds.

        Each parallel build runs as a separate nixbld user.
      '';
    };

    gc = {
      options = {
        automatic = {
          type = types.bool;
          default = false;
          description = "Whether to run nix garbage collection automatically.";
        };

        dates = {
          type = types.string;
          default = "weekly";
          example = "03:15";
          description = ''
            Schedule for automatic garbage collection.

            Accepts calendar specs like "daily", "weekly", "monthly",
            or systemd OnCalendar syntax like "03:15", "Mon..Fri 02:00".
          '';
        };

        options = {
          type = types.string;
          default = "--delete-older-than 30d";
          example = "--max-freed 1G";
          description = "Options passed to nix-collect-garbage.";
        };

        persistent = {
          type = types.bool;
          default = true;
          description = "Whether to catch up on missed GC runs after sleep/shutdown.";
        };

        randomizedDelay = {
          type = types.nullOr types.int;
          default = null;
          example = 1800;
          description = "Random delay in seconds before GC to prevent thundering herd.";
        };
      };
      description = "Automatic nix garbage collection settings.";
    };

    optimise = {
      options = {
        automatic = {
          type = types.bool;
          default = false;
          description = ''
            Whether to automatically optimise the Nix store (deduplicate via hard links).
          '';
        };

        dates = {
          type = types.string;
          default = "03:45";
          example = "weekly";
          description = "Schedule for automatic store optimization (calendar spec).";
        };

        persistent = {
          type = types.bool;
          default = true;
          description = "Whether to catch up on missed optimise runs.";
        };
      };
      description = "Automatic Nix store optimization settings.";
    };

    checkConfig = {
      type = types.bool;
      default = true;
      description = ''
        Whether to check that the generated nix.conf is valid
        at build time.
      '';
    };

    checkAllErrors = {
      type = types.bool;
      default = true;
      description = ''
        Whether nix.conf validation checks for any kind of error.
        When false, only unknown settings are checked.
      '';
    };

    distributedBuilds = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable distributed builds to remote machines
        defined in nix.buildMachines.
      '';
    };

    buildMachines = {
      # TODO(adios-cutover): submodule validation lost. Legacy validated each
      # machine (hostName, protocol ssh/ssh-ng, system/systems, sshUser,
      # sshKey, maxJobs, speedFactor, mandatoryFeatures, supportedFeatures,
      # publicHostKey).
      type = types.listOf types.attrs;
      default = [ ];
      description = ''
        Remote machines for distributed Nix builds.

        See https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-builders
      '';
    };

    registry = {
      # TODO(adios-cutover): submodule validation lost. Legacy validated each
      # entry (from/to attrsets, exact bool, flake).
      type = types.attrsOf types.attrs;
      default = { };
      description = ''
        System-wide flake registry.

        Maps flake references to other flake references, allowing
        e.g. 'nixpkgs' to resolve to a specific version.
      '';
    };

    sshServe = {
      options = {
        enable = {
          type = types.bool;
          default = false;
          description = ''
            Whether to enable serving the Nix store over SSH.

            Allows other machines to use this machine as a binary cache
            via SSH.
          '';
        };

        keys = {
          type = types.listOf types.string;
          default = [ ];
          description = "SSH public keys allowed to access the Nix store.";
        };

        protocol = {
          type = types.enum "ssh-serve-protocol" [
            "ssh"
            "ssh-ng"
          ];
          default = "ssh-ng";
          description = "Nix store protocol to use for SSH serving.";
        };

        write = {
          type = types.bool;
          default = false;
          description = "Whether to allow writing to the Nix store over SSH.";
        };
      };
      description = "Nix store SSH serving settings.";
    };

    daemonCPUSchedPolicy = {
      type = types.enum "daemon-cpu-sched-policy" [
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

    daemonIOSchedClass = {
      type = types.enum "daemon-io-sched-class" [
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

    daemonIOSchedPriority = {
      type = types.int;
      default = 4;
      description = ''
        I/O scheduling priority for the Nix daemon (0=highest, 7=lowest).
        Only used with best-effort scheduling class.
      '';
    };

    channel = {
      options = {
        enable = {
          type = types.bool;
          default = true;
          description = "Whether to enable the default Nix channel.";
        };
      };
      description = "Nix channel settings.";
    };
  };

  assertions = [
    {
      verify = { options }: options.nrBuildUsers >= 0;
      explain = { options }: "nrBuildUsers must be non-negative, got ${toString options.nrBuildUsers}";
    }
    {
      verify = { options }: options.daemonIOSchedPriority >= 0 && options.daemonIOSchedPriority <= 7;
      explain =
        { options }: "daemonIOSchedPriority must be 0-7, got ${toString options.daemonIOSchedPriority}";
    }
  ];

  impl =
    { options, ... }:
    let
      optionalString = cond: s: if cond then s else "";
      mapAttrsToList = f: set: builtins.map (n: f n set.${n}) (builtins.attrNames set);

      # Format a nix.conf value
      formatValue =
        v:
        if builtins.isBool v then
          (if v then "true" else "false")
        else if builtins.isList v then
          builtins.concatStringsSep " " (builtins.map toString v)
        else
          toString v;

      # Generate nix.conf from settings
      nixConf = builtins.concatStringsSep "\n" (
        mapAttrsToList (name: value: "${name} = ${formatValue value}") options.settings
      );

      # Generate nix-path setting
      nixPathConf = optionalString (options.nixPath != [ ]) (
        "nix-path = ${builtins.concatStringsSep ":" options.nixPath}"
      );

      buildUsers =
        if (options.nrBuildUsers > 0) then
          builtins.listToAttrs (
            builtins.genList (
              i:
              let
                n = i + 1;
              in
              {
                name = "nixbld${toString n}";
                value = {
                  uid = 30000 + n;
                  group = "nixbld";
                  description = "Nix build user ${toString n}";
                  isSystemUser = true;
                  homeDirectory = "/var/empty";
                  shell = "/run/current-system/sw/bin/nologin";
                };
              }
            ) options.nrBuildUsers
          )
        else
          { };

      sshServeUser =
        if options.sshServe.enable then
          {
            nix-ssh = {
              description = "Nix SSH store user";
              isSystemUser = true;
              group = "nogroup";
              shell = "${options.package}/bin/nix-store --serve ${optionalString options.sshServe.write "--write"}";
              openssh.authorizedKeys.keys = options.sshServe.keys;
            };
          }
        else
          { };
    in
    {
      # Default sane settings
      # TODO(adios-cutover): priority lost (each value was mkDefault).
      nix.settings = {
        max-jobs = "auto";
        cores = 0;
        sandbox = true;
        experimental-features = "nix-command flakes";
      };

      # Generate /etc/nix/nix.conf
      environment.etc."nix/nix.conf".text = ''
        # Generated by ekaos nix-daemon module
        ${nixConf}
        ${nixPathConf}
        ${optionalString (options.extraOptions != "") ''

          # Extra options
          ${options.extraOptions}
        ''}
      '';

      # Create nix directories and build users
      system.activationScripts.nix-daemon = {
        deps = [ "etc" ];
        text = ''
          mkdir -p /etc/nix
          mkdir -p /nix/var/nix/profiles/per-user
          mkdir -p /nix/var/nix/gcroots/per-user

          # Ensure nixbld group exists and create build users
          ${optionalString (options.nrBuildUsers > 0) ''
            for i in $(seq 1 ${toString options.nrBuildUsers}); do
              if ! id "nixbld$i" >/dev/null 2>&1; then
                echo "Build user nixbld$i should be created by user management"
              fi
            done
          ''}
        '';
      };

      # Build users
      users.groups =
        if (options.nrBuildUsers > 0) then
          {
            nixbld = {
              gid = 30000;
              members = builtins.genList (i: "nixbld${toString (i + 1)}") options.nrBuildUsers;
            };
          }
        else
          { };

      users.users = buildUsers // sshServeUser;

      # Generate /etc/nix/machines for distributed builds
      environment.etc."nix/machines" =
        if (options.buildMachines != [ ]) then
          {
            text = builtins.concatStringsSep "\n" (
              builtins.map (
                m:
                let
                  systems = if m.system != null then [ m.system ] else m.systems;
                  protocol = if m.protocol != null then "${m.protocol}://" else "";
                  user = optionalString (m.sshUser != null) "${m.sshUser}@";
                  key = optionalString (m.sshKey != null) " ${m.sshKey}";
                in
                "${protocol}${user}${m.hostName} ${builtins.concatStringsSep "," systems} ${key} ${toString m.maxJobs} ${toString m.speedFactor} ${builtins.concatStringsSep "," m.supportedFeatures} ${builtins.concatStringsSep "," m.mandatoryFeatures}"
              ) options.buildMachines
            );
          }
        else
          { };

      nix.settings.builders = if options.distributedBuilds then "@/etc/nix/machines" else null;

      # Generate flake registry
      environment.etc."nix/registry.json" =
        if (options.registry != { }) then
          {
            text = builtins.toJSON {
              version = 2;
              flakes = mapAttrsToList (
                name: entry:
                {
                  inherit (entry) from to exact;
                }
                // (
                  if (entry.from == { }) then
                    {
                      from = {
                        type = "indirect";
                        id = name;
                      };
                    }
                  else
                    { }
                )
              ) options.registry;
            };
          }
        else
          { };

      # Automatic GC via timers
      timers.nix-gc =
        if options.gc.automatic then
          {
            enable = true;
            description = "Nix garbage collection";
            schedule.calendar = options.gc.dates;
            schedule.persistent = options.gc.persistent;
            schedule.randomDelay = options.gc.randomizedDelay;
            script = "${options.package}/bin/nix-collect-garbage ${options.gc.options}";
            user = "root";
          }
        else
          { };

      # Automatic store optimization via timers
      timers.nix-optimise =
        if options.optimise.automatic then
          {
            enable = true;
            description = "Nix store optimization";
            schedule.calendar = options.optimise.dates;
            schedule.persistent = options.optimise.persistent;
            script = "${options.package}/bin/nix store optimise";
            user = "root";
          }
        else
          { };
    };
}
