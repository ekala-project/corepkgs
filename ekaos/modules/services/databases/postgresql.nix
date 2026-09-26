# Adios port of ekaos/modules/services/databases/postgresql.nix.
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
      description = "Whether to enable the PostgreSQL database server.";
    };

    description = {
      type = types.string;
      default = "PostgreSQL Database Server";
      description = "Service description.";
    };

    user = {
      type = types.string;
      default = "postgres";
      description = "User to run PostgreSQL as.";
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
      default = pkgs.postgresql;
      description = "PostgreSQL package to use.";
    };

    dataDir = {
      type = types.string;
      # TODO(adios-cutover): legacy default derived from the package version
      # ("/var/lib/postgresql/<version>"); defaultFunc reads the sibling option.
      defaultFunc = { options, ... }: "/var/lib/postgresql/${options.package.psqlSchema}";
      description = "Data directory for PostgreSQL.";
    };

    settings = {
      options = {
        port = {
          type = types.int;
          default = 5432;
          description = "Port for PostgreSQL to listen on.";
        };

        listenAddresses = {
          type = types.string;
          default = "localhost";
          description = "Addresses to listen on. '*' for all interfaces.";
        };

        maxConnections = {
          type = types.int;
          default = 100;
          description = "Maximum number of concurrent connections.";
        };

        sharedBuffers = {
          type = types.string;
          default = "128MB";
          description = "Amount of memory for shared buffers.";
        };

        workMem = {
          type = types.string;
          default = "4MB";
          description = "Amount of memory for internal sort operations.";
        };

        walLevel = {
          type = types.enum "walLevel" [
            "minimal"
            "replica"
            "logical"
          ];
          default = "replica";
          description = "WAL level for replication and recovery.";
        };

        logDestination = {
          type = types.enum "logDestination" [
            "stderr"
            "csvlog"
            "syslog"
          ];
          default = "stderr";
          description = "Where to send log output.";
        };

        authentication = {
          options = {
            local = {
              type = types.string;
              default = "peer";
              description = "Authentication method for local (Unix socket) connections.";
            };

            host = {
              type = types.string;
              default = "md5";
              description = "Authentication method for TCP/IP connections.";
            };

            extraRules = {
              type = types.string;
              default = "";
              description = "Additional pg_hba.conf rules.";
            };
          };
          description = "Authentication configuration.";
        };

        extraConfig = {
          type = types.string;
          default = "";
          description = "Extra postgresql.conf settings.";
        };
      };
      description = "PostgreSQL configuration.";
    };

    initialScript = {
      type = types.nullOr types.pathLike;
      default = null;
      description = "SQL script to run on first initialization.";
    };

    ensureDatabases = {
      type = types.listOf types.string;
      default = [ ];
      description = "Databases to ensure exist after startup.";
    };

    ensureUsers = {
      # TODO(adios-cutover): submodule validation lost (name,
      # ensureDBOwnership=false per entry).
      type = types.listOf types.attrs;
      default = [ ];
      description = "Users to ensure exist after startup.";
    };
  };

  assertions = [
    {
      verify =
        { options }: (options.settings.port or 5432) >= 0 && (options.settings.port or 5432) <= 65535;
      explain =
        { options }: "postgresql port must be 0-65535, got ${toString (options.settings.port or 5432)}";
    }
  ];

  impl =
    { options, ... }:
    if !options.enable then
      { }
    else
      let
        s = options.settings;
        auth = s.authentication or { };
        port = s.port or 5432;
        listenAddresses = s.listenAddresses or "localhost";

        pgHbaConf = pkgs.writeText "pg_hba.conf" ''
          # TYPE  DATABASE        USER            ADDRESS                 METHOD
          local   all             all                                     ${auth.local or "peer"}
          host    all             all             127.0.0.1/32            ${auth.host or "md5"}
          host    all             all             ::1/128                 ${auth.host or "md5"}
          ${auth.extraRules or ""}
        '';

        pgConf = pkgs.writeText "postgresql.conf" ''
          # Connection settings
          listen_addresses = '${listenAddresses}'
          port = ${toString port}
          max_connections = ${toString (s.maxConnections or 100)}

          # Data directory
          data_directory = '${options.dataDir}'

          # Authentication
          hba_file = '${pgHbaConf}'

          # Logging
          log_destination = '${s.logDestination or "stderr"}'
          logging_collector = ${if (s.logDestination or "stderr") == "csvlog" then "on" else "off"}

          # Memory
          shared_buffers = '${s.sharedBuffers or "128MB"}'
          work_mem = '${s.workMem or "4MB"}'

          # WAL
          wal_level = '${s.walLevel or "replica"}'

          ${s.extraConfig or ""}
        '';
      in
      {
        services.postgresql = {
          inherit (options)
            enable
            description
            user
            restartPolicy
            ;
          command = "${options.package}/bin/postgres";
          args = [
            "-D"
            options.dataDir
            "-c"
            "config_file=${pgConf}"
          ];
          ports = options.ports // {
            postgresql = {
              port = port;
              protocol = "tcp";
              transport = "tcp";
              internal = listenAddresses == "localhost";
              openFirewall = listenAddresses != "localhost";
            };
          };
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
          description = "PostgreSQL server user";
        };
        users.groups.${options.user} = { };

        # TODO(adios-cutover): legacy ordering (after "etc" "users") lost; plain script.
        system.activationScripts.postgresql = ''
          # Create data directory
          mkdir -p ${options.dataDir}
          chown ${options.user}:${options.user} ${options.dataDir}
          chmod 700 ${options.dataDir}

          # Initialize database if not already done
          if [ ! -f ${options.dataDir}/PG_VERSION ]; then
            echo "Initializing PostgreSQL database..."
            su -s /bin/sh ${options.user} -c '${options.package}/bin/initdb -D ${options.dataDir}'

            ${
              if options.initialScript != null then
                ''
                  echo "Running initial script..."
                  su -s /bin/sh ${options.user} -c '${options.package}/bin/pg_ctl -D ${options.dataDir} -w start'
                  su -s /bin/sh ${options.user} -c '${options.package}/bin/psql -f ${options.initialScript}'
                  su -s /bin/sh ${options.user} -c '${options.package}/bin/pg_ctl -D ${options.dataDir} -w stop'
                ''
              else
                ""
            }
          fi

          ${
            if (options.ensureDatabases != [ ] || options.ensureUsers != [ ]) then
              ''
                # Ensure databases and users (run after service starts)
                # This is handled by a post-start hook
              ''
            else
              ""
          }
        '';

        environment.systemPackages = [ options.package ];
      };
}
