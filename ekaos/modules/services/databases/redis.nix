# Adios port of ekaos/modules/services/databases/redis.nix.
# TODO(adios-cutover): command/args were internal options set by the legacy
# config; they are computed in impl, not user options.
# TODO(adios-cutover): ports used the shared portContract submodule type
# (imported from services/lib/types.nix); submodule validation lost.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Whether to enable the Redis in-memory data store.";
    };

    description = {
      type = types.string;
      default = "Redis Server";
      description = "Service description.";
    };

    user = {
      type = types.string;
      default = "redis";
      description = "User to run Redis as.";
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

    ports = {
      type = types.attrsOf types.attrs;
      default = { };
      description = "Port contracts for this service.";
    };

    package = {
      type = types.derivation;
      default = pkgs.redis;
      description = "Redis package to use.";
    };

    dataDir = {
      type = types.string;
      default = "/var/lib/redis";
      description = "Data directory for Redis persistence.";
    };

    settings = {
      options = {
        port = {
          type = types.int;
          default = 6379;
          description = "TCP port for Redis to listen on. Set to 0 to disable TCP.";
        };

        bind = {
          type = types.string;
          default = "127.0.0.1";
          description = ''
            Interface to bind to.
            Use "0.0.0.0" to listen on all interfaces.
          '';
        };

        unixSocket = {
          type = types.nullOr types.string;
          default = "/run/redis/redis.sock";
          description = "Path to Unix socket. null disables Unix socket.";
        };

        unixSocketPerm = {
          type = types.int;
          default = 660;
          description = "Permissions for the Unix socket.";
        };

        maxMemory = {
          type = types.nullOr types.string;
          default = null;
          description = ''
            Maximum memory Redis will use. null means no limit.
            Supports suffixes: kb, mb, gb.
          '';
        };

        maxMemoryPolicy = {
          type = types.enum "maxMemoryPolicy" [
            "volatile-lru"
            "allkeys-lru"
            "volatile-lfu"
            "allkeys-lfu"
            "volatile-random"
            "allkeys-random"
            "volatile-ttl"
            "noeviction"
          ];
          default = "noeviction";
          description = "Eviction policy when maxMemory is reached.";
        };

        databases = {
          type = types.int;
          default = 16;
          description = "Number of databases.";
        };

        maxClients = {
          type = types.int;
          default = 10000;
          description = "Maximum number of connected clients.";
        };

        logLevel = {
          type = types.enum "logLevel" [
            "debug"
            "verbose"
            "notice"
            "warning"
          ];
          default = "notice";
          description = "Server verbosity level.";
        };

        save = {
          type = types.listOf (types.listOf types.int);
          default = [
            [
              900
              1
            ]
            [
              300
              10
            ]
            [
              60
              10000
            ]
          ];
          description = ''
            RDB persistence schedule. Each element is [seconds changes].
            Set to empty list to disable RDB persistence.
          '';
        };

        appendOnly = {
          type = types.bool;
          default = false;
          description = "Whether to enable append-only file (AOF) persistence.";
        };

        appendFsync = {
          type = types.enum "appendFsync" [
            "always"
            "everysec"
            "no"
          ];
          default = "everysec";
          description = "How often to fsync the AOF log.";
        };

        requirePassFile = {
          type = types.nullOr types.pathLike;
          default = null;
          description = ''
            Path to file containing the Redis password.
            The file is read at service startup and the password is injected
            into the runtime configuration, avoiding storage in the nix store.
          '';
        };

        slowLogSlowerThan = {
          type = types.int;
          default = 10000;
          description = "Log queries slower than this many microseconds.";
        };

        slowLogMaxLen = {
          type = types.int;
          default = 128;
          description = "Maximum number of slow log entries.";
        };

        extraConfig = {
          type = types.string;
          default = "";
          description = "Extra configuration appended to redis.conf.";
        };
      };
      description = "Redis configuration.";
    };
  };

  assertions = [
    {
      verify =
        { options }: (options.settings.port or 6379) >= 0 && (options.settings.port or 6379) <= 65535;
      explain =
        { options }: "redis port must be 0-65535, got ${toString (options.settings.port or 6379)}";
    }
  ];

  impl =
    { options, ... }:
    if !options.enable then
      { }
    else
      let
        s = options.settings;
        port = s.port or 6379;
        bind = s.bind or "127.0.0.1";

        mkValueString =
          value:
          if value == true then
            "yes"
          else if value == false then
            "no"
          else
            toString value;

        redisConf = pkgs.writeText "redis.conf" ''
          # Generated by ekaos redis module

          # Network
          bind ${bind}
          port ${toString port}
          ${
            if (s.unixSocket or null) != null then
              ''
                unixsocket ${s.unixSocket}
                unixsocketperm ${toString (s.unixSocketPerm or 660)}
              ''
            else
              ""
          }

          # General
          daemonize no
          loglevel ${s.logLevel or "notice"}
          logfile ""
          syslog-enabled yes
          databases ${toString (s.databases or 16)}
          maxclients ${toString (s.maxClients or 10000)}

          # Memory
          ${
            if (s.maxMemory or null) != null then
              ''
                maxmemory ${s.maxMemory}
                maxmemory-policy ${s.maxMemoryPolicy or "noeviction"}
              ''
            else
              ""
          }

          # RDB Persistence
          ${
            if (s.save or [ ]) == [ ] then
              ''save ""''
            else
              builtins.concatStringsSep "\n" (
                builtins.map (e: "save ${toString (builtins.elemAt e 0)} ${toString (builtins.elemAt e 1)}") s.save
              )
          }
          dbfilename dump.rdb
          dir ${options.dataDir}

          # AOF Persistence
          appendonly ${mkValueString (s.appendOnly or false)}
          appendfsync ${s.appendFsync or "everysec"}

          # Slow log
          slowlog-log-slower-than ${toString (s.slowLogSlowerThan or 10000)}
          slowlog-max-len ${toString (s.slowLogMaxLen or 128)}

          ${s.extraConfig or ""}
        '';
      in
      {
        services.redis = {
          inherit (options)
            enable
            description
            user
            restartPolicy
            ;
          command = "${options.package}/bin/${options.package.serverBin or "redis-server"}";
          args = [ "/var/lib/redis/redis.conf" ];
          ports =
            options.ports
            // (
              if port != 0 then
                {
                  redis = {
                    port = port;
                    protocol = "tcp";
                    transport = "tcp";
                    internal = bind == "127.0.0.1";
                    openFirewall = bind != "127.0.0.1";
                  };
                }
              else
                { }
            );
          systemd = {
            after = [
              "network.target"
              "local-fs.target"
            ];
            wantedBy = [ "multi-user.target" ];
          }
          // options.systemd;
        };

        users.users.${options.user} = {
          isSystemUser = true;
          homeDirectory = options.dataDir;
          group = options.user;
          description = "Redis server user";
        };
        users.groups.${options.user} = { };

        environment.systemPackages = [ options.package ];

        # TODO(adios-cutover): legacy ordering (after "etc" "users") lost; plain script.
        system.activationScripts.redis = ''
          # Create data directory
          mkdir -p ${options.dataDir}
          chown ${options.user}:${options.user} ${options.dataDir}
          chmod 700 ${options.dataDir}

          # Create runtime directory
          mkdir -p /run/redis
          chown ${options.user}:${options.user} /run/redis
          chmod 750 /run/redis

          # Generate runtime config (includes password from file if configured)
          cp ${redisConf} ${options.dataDir}/redis.conf
          ${
            if (s.requirePassFile or null) != null then
              ''
                if [ -f ${s.requirePassFile} ]; then
                  echo "requirepass $(cat ${s.requirePassFile})" >> ${options.dataDir}/redis.conf
                fi
              ''
            else
              ""
          }
          chown ${options.user}:${options.user} ${options.dataDir}/redis.conf
          chmod 600 ${options.dataDir}/redis.conf
        '';
      };
}
