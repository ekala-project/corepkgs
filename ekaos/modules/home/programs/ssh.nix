# Per-user SSH client configuration
#
# Extends home.users.<name> with structured SSH client options.
# Generates ~/.ssh/config from matchBlocks, global options, and
# extraConfig.
#
# Usage:
#   home.users.alice.programs.ssh = {
#     enable = true;
#     matchBlocks = {
#       work = {
#         hostname = "dev.example.com";
#         user = "alice";
#         identityFile = "~/.ssh/work_ed25519";
#         forwardAgent = true;
#       };
#       "github.com" = {
#         identityFile = "~/.ssh/github_ed25519";
#       };
#     };
#     extraConfig = ''
#       VisualHostKey yes
#     '';
#   };
{ lib, ... }:

let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    concatStringsSep
    mapAttrsToList
    optional
    optionalString
    literalExpression
    ;

  # SSH match block submodule
  matchBlockOpts =
    { name, ... }:
    {
      options = {
        host = mkOption {
          type = types.str;
          default = name;
          description = "Host pattern for this block. Defaults to the attribute name.";
        };

        hostname = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "192.168.1.100";
          description = "Real hostname to connect to.";
        };

        user = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Username for this host.";
        };

        port = mkOption {
          type = types.nullOr types.port;
          default = null;
          description = "Port number.";
        };

        identityFile = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "~/.ssh/id_ed25519";
          description = "Path to the identity (private key) file.";
        };

        identitiesOnly = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Only use the specified identity file.";
        };

        forwardAgent = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Whether to forward the SSH agent.";
        };

        forwardX11 = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Whether to forward X11.";
        };

        proxyJump = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "bastion.example.com";
          description = "Host to use as a jump proxy.";
        };

        proxyCommand = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Command to use for proxying.";
        };

        localForwards = mkOption {
          type = types.listOf (
            types.submodule {
              options = {
                bind.port = mkOption {
                  type = types.nullOr types.port;
                  default = null;
                  description = "Bind port (for TCP forwards).";
                };
                bind.address = mkOption {
                  type = types.str;
                  default = "localhost";
                  description = "Bind address (for TCP) or socket path (for Unix socket forwards).";
                };
                host.port = mkOption {
                  type = types.nullOr types.port;
                  default = null;
                  description = "Host port (for TCP forwards).";
                };
                host.address = mkOption {
                  type = types.str;
                  default = "localhost";
                  description = "Host address (for TCP) or socket path (for Unix socket forwards).";
                };
              };
            }
          );
          default = [ ];
          description = ''
            Local port forwards. Supports both TCP (address:port) and
            Unix socket (path) forwards.
          '';
        };

        remoteForwards = mkOption {
          type = types.listOf (
            types.submodule {
              options = {
                bind.port = mkOption {
                  type = types.nullOr types.port;
                  default = null;
                  description = "Bind port (for TCP forwards).";
                };
                bind.address = mkOption {
                  type = types.str;
                  default = "localhost";
                  description = "Bind address (for TCP) or socket path (for Unix socket forwards).";
                };
                host.port = mkOption {
                  type = types.nullOr types.port;
                  default = null;
                  description = "Host port (for TCP forwards).";
                };
                host.address = mkOption {
                  type = types.str;
                  default = "localhost";
                  description = "Host address (for TCP) or socket path (for Unix socket forwards).";
                };
              };
            }
          );
          default = [ ];
          description = ''
            Remote port forwards. Supports both TCP (address:port) and
            Unix socket (path) forwards.
          '';
          example = literalExpression ''
            [
              # TCP forward
              { bind.address = "localhost"; bind.port = 8080;
                host.address = "localhost"; host.port = 80; }
              # Unix socket forward
              { bind.address = "/run/user/1000/gnupg/S.gpg-agent";
                host.address = "/run/user/1000/gnupg/S.gpg-agent.extra"; }
            ]
          '';
        };

        extraOptions = mkOption {
          type = types.attrsOf types.str;
          default = { };
          example = literalExpression ''
            {
              ServerAliveInterval = "60";
              ServerAliveCountMax = "3";
            }
          '';
          description = "Additional SSH options for this host as key-value pairs.";
        };
      };
    };

  # Format a single match block as SSH config text
  formatMatchBlock =
    _: block:
    let
      boolToYesNo = b: if b then "yes" else "no";
      lines = [
        "Host ${block.host}"
      ]
      ++ optional (block.hostname != null) "  HostName ${block.hostname}"
      ++ optional (block.user != null) "  User ${block.user}"
      ++ optional (block.port != null) "  Port ${toString block.port}"
      ++ optional (block.identityFile != null) "  IdentityFile ${block.identityFile}"
      ++ optional (block.identitiesOnly != null) "  IdentitiesOnly ${boolToYesNo block.identitiesOnly}"
      ++ optional (block.forwardAgent != null) "  ForwardAgent ${boolToYesNo block.forwardAgent}"
      ++ optional (block.forwardX11 != null) "  ForwardX11 ${boolToYesNo block.forwardX11}"
      ++ optional (block.proxyJump != null) "  ProxyJump ${block.proxyJump}"
      ++ optional (block.proxyCommand != null) "  ProxyCommand ${block.proxyCommand}"
      ++ map (
        fwd:
        let
          bind = if fwd.bind.port != null then "${fwd.bind.address}:${toString fwd.bind.port}" else fwd.bind.address;
          host = if fwd.host.port != null then "${fwd.host.address}:${toString fwd.host.port}" else fwd.host.address;
        in
        "  LocalForward ${bind} ${host}"
      ) block.localForwards
      ++ map (
        fwd:
        let
          bind = if fwd.bind.port != null then "${fwd.bind.address}:${toString fwd.bind.port}" else fwd.bind.address;
          host = if fwd.host.port != null then "${fwd.host.address}:${toString fwd.host.port}" else fwd.host.address;
        in
        "  RemoteForward ${bind} ${host}"
      ) block.remoteForwards
      ++ mapAttrsToList (k: v: "  ${k} ${v}") block.extraOptions;
    in
    concatStringsSep "\n" lines;

  sshOpts =
    { config, ... }:
    let
      cfg = config.programs.ssh;

      boolToYesNo = b: if b then "yes" else "no";

      # Global options
      globalLines =
        optional (cfg.forwardAgent != null) "ForwardAgent ${boolToYesNo cfg.forwardAgent}"
        ++ optional (cfg.identitiesOnly != null) "IdentitiesOnly ${boolToYesNo cfg.identitiesOnly}"
        ++ optional (cfg.addKeysToAgent != null) "AddKeysToAgent ${cfg.addKeysToAgent}"
        ++ optional (cfg.hashKnownHosts != null) "HashKnownHosts ${boolToYesNo cfg.hashKnownHosts}"
        ++ optional (
          cfg.serverAliveInterval != null
        ) "ServerAliveInterval ${toString cfg.serverAliveInterval}"
        ++ optional (
          cfg.serverAliveCountMax != null
        ) "ServerAliveCountMax ${toString cfg.serverAliveCountMax}"
        ++ optional (cfg.compression != null) "Compression ${boolToYesNo cfg.compression}";

      # Assemble full config
      sshConfigContent = concatStringsSep "\n" (
        [ "# Generated by ekaos home configuration. Do not edit." ]
        ++ [ "" ]

        # Includes
        ++ map (inc: "Include ${inc}") cfg.includes

        ++ optional (cfg.includes != [ ]) ""

        # Global options
        ++ globalLines

        ++ optional (globalLines != [ ]) ""

        # Match blocks
        ++ mapAttrsToList formatMatchBlock cfg.matchBlocks

        # Extra config
        ++ optional (cfg.extraConfig != "") ""
        ++ optional (cfg.extraConfig != "") cfg.extraConfig

        ++ [ "" ]
      );
    in
    {
      options.programs.ssh = {
        enable = mkEnableOption "per-user SSH client configuration";

        matchBlocks = mkOption {
          type = types.attrsOf (types.submodule matchBlockOpts);
          default = { };
          example = literalExpression ''
            {
              work = {
                hostname = "dev.example.com";
                user = "alice";
                identityFile = "~/.ssh/work_ed25519";
              };
            }
          '';
          description = "Per-host SSH client configuration blocks.";
        };

        forwardAgent = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Global ForwardAgent setting.";
        };

        identitiesOnly = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Global IdentitiesOnly setting.";
        };

        addKeysToAgent = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "yes";
          description = "AddKeysToAgent setting (yes, no, confirm, ask).";
        };

        hashKnownHosts = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Whether to hash hostnames in known_hosts.";
        };

        serverAliveInterval = mkOption {
          type = types.nullOr types.int;
          default = null;
          example = 60;
          description = "Seconds between keepalive messages.";
        };

        serverAliveCountMax = mkOption {
          type = types.nullOr types.int;
          default = null;
          example = 3;
          description = "Max keepalive messages before disconnect.";
        };

        compression = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Whether to enable compression.";
        };

        includes = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "~/.ssh/config.d/*" ];
          description = "Files to include in SSH config.";
        };

        extraConfig = mkOption {
          type = types.lines;
          default = "";
          description = "Additional SSH config appended at the end.";
        };
      };

      config = mkIf cfg.enable {
        file.".ssh/config".text = sshConfigContent;
      };
    };
in

{
  options.home.users = mkOption {
    type = types.attrsOf (types.submodule sshOpts);
  };
}
