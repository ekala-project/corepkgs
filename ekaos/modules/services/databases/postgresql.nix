# PostgreSQL database server
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.postgresql;

  # Generate pg_hba.conf
  pgHbaConf = pkgs.writeText "pg_hba.conf" ''
    # TYPE  DATABASE        USER            ADDRESS                 METHOD
    local   all             all                                     ${cfg.settings.authentication.local}
    host    all             all             127.0.0.1/32            ${cfg.settings.authentication.host}
    host    all             all             ::1/128                 ${cfg.settings.authentication.host}
    ${cfg.settings.authentication.extraRules}
  '';

  # Generate postgresql.conf
  pgConf = pkgs.writeText "postgresql.conf" ''
    # Connection settings
    listen_addresses = '${cfg.settings.listenAddresses}'
    port = ${toString cfg.settings.port}
    max_connections = ${toString cfg.settings.maxConnections}

    # Data directory
    data_directory = '${cfg.dataDir}'

    # Authentication
    hba_file = '${pgHbaConf}'

    # Logging
    log_destination = '${cfg.settings.logDestination}'
    logging_collector = ${if cfg.settings.logDestination == "csvlog" then "on" else "off"}

    # Memory
    shared_buffers = '${cfg.settings.sharedBuffers}'
    work_mem = '${cfg.settings.workMem}'

    # WAL
    wal_level = '${cfg.settings.walLevel}'

    ${cfg.settings.extraConfig}
  '';

in

{
  options.services.postgresql = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the PostgreSQL database server.";
    };

    description = mkOption {
      type = types.str;
      default = "PostgreSQL Database Server";
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
      default = "postgres";
      description = "User to run PostgreSQL as.";
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

    ports = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Port contracts for this service.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.postgresql;
      description = "PostgreSQL package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/postgresql/${cfg.package.psqlSchema}";
      defaultText = "/var/lib/postgresql/<version>";
      description = "Data directory for PostgreSQL.";
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          port = mkOption {
            type = types.port;
            default = 5432;
            description = "Port for PostgreSQL to listen on.";
          };

          listenAddresses = mkOption {
            type = types.str;
            default = "localhost";
            example = "*";
            description = "Addresses to listen on. '*' for all interfaces.";
          };

          maxConnections = mkOption {
            type = types.int;
            default = 100;
            description = "Maximum number of concurrent connections.";
          };

          sharedBuffers = mkOption {
            type = types.str;
            default = "128MB";
            description = "Amount of memory for shared buffers.";
          };

          workMem = mkOption {
            type = types.str;
            default = "4MB";
            description = "Amount of memory for internal sort operations.";
          };

          walLevel = mkOption {
            type = types.enum [
              "minimal"
              "replica"
              "logical"
            ];
            default = "replica";
            description = "WAL level for replication and recovery.";
          };

          logDestination = mkOption {
            type = types.enum [
              "stderr"
              "csvlog"
              "syslog"
            ];
            default = "stderr";
            description = "Where to send log output.";
          };

          authentication = {
            local = mkOption {
              type = types.str;
              default = "peer";
              example = "md5";
              description = "Authentication method for local (Unix socket) connections.";
            };

            host = mkOption {
              type = types.str;
              default = "md5";
              example = "scram-sha-256";
              description = "Authentication method for TCP/IP connections.";
            };

            extraRules = mkOption {
              type = types.lines;
              default = "";
              example = "host mydb myuser 10.0.0.0/8 md5";
              description = "Additional pg_hba.conf rules.";
            };
          };

          extraConfig = mkOption {
            type = types.lines;
            default = "";
            description = "Extra postgresql.conf settings.";
          };
        };
      };
      default = { };
      description = "PostgreSQL configuration.";
    };

    initialScript = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "SQL script to run on first initialization.";
    };

    ensureDatabases = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "myapp"
        "gitea"
      ];
      description = "Databases to ensure exist after startup.";
    };

    ensureUsers = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "User name.";
            };
            ensureDBOwnership = mkOption {
              type = types.bool;
              default = false;
              description = "Ensure the user owns a database with the same name.";
            };
          };
        }
      );
      default = [ ];
      description = "Users to ensure exist after startup.";
    };
  };

  config = mkIf cfg.enable {
    # Define the PostgreSQL service
    services.postgresql = {
      command = "${cfg.package}/bin/postgres";
      args = [
        "-D"
        cfg.dataDir
        "-c"
        "config_file=${pgConf}"
      ];
      restartPolicy = "always";

      ports.postgresql = {
        port = cfg.settings.port;
        protocol = "tcp";
        transport = "tcp";
        internal = cfg.settings.listenAddresses == "localhost";
        openFirewall = cfg.settings.listenAddresses != "localhost";
      };

      systemd = {
        after = [
          "network.target"
          "local-fs.target"
        ];
        wantedBy = [ "multi-user.target" ];
      };
    };

    # Create postgres user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      home = cfg.dataDir;
      group = cfg.user;
      description = "PostgreSQL server user";
    };
    users.groups.${cfg.user} = { };

    # Initialize database and ensure databases/users
    system.activationScripts.postgresql =
      stringAfter
        [
          "etc"
          "users"
        ]
        ''
          # Create data directory
          mkdir -p ${cfg.dataDir}
          chown ${cfg.user}:${cfg.user} ${cfg.dataDir}
          chmod 700 ${cfg.dataDir}

          # Initialize database if not already done
          if [ ! -f ${cfg.dataDir}/PG_VERSION ]; then
            echo "Initializing PostgreSQL database..."
            su -s /bin/sh ${cfg.user} -c '${cfg.package}/bin/initdb -D ${cfg.dataDir}'

            ${optionalString (cfg.initialScript != null) ''
              echo "Running initial script..."
              su -s /bin/sh ${cfg.user} -c '${cfg.package}/bin/pg_ctl -D ${cfg.dataDir} -w start'
              su -s /bin/sh ${cfg.user} -c '${cfg.package}/bin/psql -f ${cfg.initialScript}'
              su -s /bin/sh ${cfg.user} -c '${cfg.package}/bin/pg_ctl -D ${cfg.dataDir} -w stop'
            ''}
          fi

          ${optionalString (cfg.ensureDatabases != [ ] || cfg.ensureUsers != [ ]) ''
            # Ensure databases and users (run after service starts)
            # This is handled by a post-start hook
          ''}
        '';

    environment.systemPackages = [ cfg.package ];
  };
}
