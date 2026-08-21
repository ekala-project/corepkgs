# HashiCorp Vault secrets management
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.vault;

  configFile = pkgs.writeText "vault.hcl" ''
    ${optionalString (!cfg.dev) ''
      listener "tcp" {
        address = "${cfg.settings.address}"
        ${
          if (cfg.settings.tlsCertFile == null || cfg.settings.tlsKeyFile == null) then
            ''
              tls_disable = "true"
            ''
          else
            ''
              tls_cert_file = "${cfg.settings.tlsCertFile}"
              tls_key_file = "${cfg.settings.tlsKeyFile}"
            ''
        }
        ${cfg.settings.listenerExtraConfig}
      }
    ''}

    storage "${cfg.settings.storageBackend}" {
      ${optionalString (cfg.settings.storagePath != null) ''path = "${cfg.settings.storagePath}"''}
      ${cfg.settings.storageConfig}
    }

    ${optionalString (cfg.settings.telemetryConfig != "") ''
      telemetry {
        ${cfg.settings.telemetryConfig}
      }
    ''}

    ${cfg.settings.extraConfig}
  '';

  allConfigPaths = [ configFile ] ++ cfg.extraSettingsPaths;
  configArgs = concatMap (p: [
    "-config"
    p
  ]) allConfigPaths;

  vaultArgs =
    optional cfg.dev "-dev"
    ++ optional (cfg.dev && cfg.devRootTokenID != null) "-dev-root-token-id=${cfg.devRootTokenID}"
    ++ configArgs;

  useTLS = cfg.settings.tlsCertFile != null && cfg.settings.tlsKeyFile != null;
  needsStorage = cfg.settings.storageBackend == "file" || cfg.settings.storageBackend == "raft";

in

{
  options.services.vault = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the HashiCorp Vault secrets management server.";
    };

    description = mkOption {
      type = types.str;
      default = "HashiCorp Vault";
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
      default = "vault";
      description = "User to run Vault as.";
    };

    restartPolicy = mkOption {
      type = types.str;
      default = "on-failure";
      description = "Restart policy.";
    };

    systemd = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Systemd-specific options.";
    };

    ports = mkOption {
      type = types.attrsOf (
        types.submodule (import ../../../../services/lib/types.nix { inherit lib; }).portContract
      );
      default = { };
      description = "Port contracts for this service.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.vault;
      description = "Vault package to use.";
    };

    dev = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Run Vault in dev mode. In dev mode, Vault runs in-memory and starts
        unsealed. Not for production use.
      '';
    };

    devRootTokenID = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Initial root token for dev mode.";
    };

    extraSettingsPaths = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = ''
        Additional HCL or JSON configuration files to load.
        Use this to provide secrets (e.g. storage credentials) without
        placing them in the nix store.
      '';
      example = [ "/run/secrets/vault-storage.hcl" ];
    };

    settings = mkOption {
      type = types.submodule {
        options = {
          address = mkOption {
            type = types.str;
            default = "127.0.0.1:8200";
            description = "Listener address (host:port).";
          };

          storageBackend = mkOption {
            type = types.enum [
              "inmem"
              "file"
              "raft"
              "consul"
              "postgresql"
            ];
            default = "file";
            description = "Storage backend type.";
          };

          storagePath = mkOption {
            type = types.nullOr types.str;
            default = if needsStorage then "/var/lib/vault" else null;
            defaultText = ''"/var/lib/vault" for file/raft backends, null otherwise'';
            description = "Data directory for file or raft storage backend.";
          };

          storageConfig = mkOption {
            type = types.lines;
            default = "";
            description = ''
              Extra HCL for the storage block.
              Confidential values (connection strings, credentials) should be
              provided via extraSettingsPaths instead.
            '';
          };

          tlsCertFile = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "/var/lib/acme/vault.example.com/fullchain.pem";
            description = "Path to TLS certificate. null disables TLS.";
          };

          tlsKeyFile = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "/var/lib/acme/vault.example.com/key.pem";
            description = "Path to TLS private key. null disables TLS.";
          };

          listenerExtraConfig = mkOption {
            type = types.lines;
            default = ''
              tls_min_version = "tls12"
            '';
            description = "Extra HCL appended to the listener block.";
          };

          telemetryConfig = mkOption {
            type = types.lines;
            default = "";
            example = ''
              prometheus_retention_time = "30s"
              disable_hostname = true
            '';
            description = "HCL for the telemetry block. Empty string disables telemetry.";
          };

          extraConfig = mkOption {
            type = types.lines;
            default = "";
            description = "Extra HCL appended to vault.hcl.";
          };
        };
      };
      default = { };
      description = "Vault configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          cfg.settings.storageBackend == "inmem"
          -> (cfg.settings.storagePath == null && cfg.settings.storageConfig == "");
        message = ''The "inmem" storage backend expects no storagePath or storageConfig.'';
      }
    ];

    # Define the Vault service
    services.vault = {
      command = "${cfg.package}/bin/vault";
      args = [ "server" ] ++ vaultArgs;
      restartPolicy = "on-failure";

      ports.vault = {
        port =
          let
            # Parse port from address string "host:port"
            parts = splitString ":" cfg.settings.address;
          in
          toInt (last parts);
        protocol = "tcp";
        transport = if useTLS then "https" else "http";
        internal = hasPrefix "127.0.0.1" cfg.settings.address;
        openFirewall = !hasPrefix "127.0.0.1" cfg.settings.address;
        healthCheck.path = "/v1/sys/health";
      };

      systemd = {
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
      };
    };

    # Create vault user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
      description = "Vault secrets management user";
    };
    users.groups.${cfg.user} = { };

    # Install vault CLI
    environment.systemPackages = [ cfg.package ];

    # Initialize storage directory
    system.activationScripts.vault = stringAfter [ "etc" "users" ] ''
      ${optionalString (cfg.settings.storagePath != null) ''
        mkdir -p ${cfg.settings.storagePath}
        chown ${cfg.user}:${cfg.user} ${cfg.settings.storagePath}
        chmod 700 ${cfg.settings.storagePath}
      ''}
    '';
  };
}
