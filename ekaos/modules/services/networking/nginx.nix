# Nginx web server / reverse proxy service module
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.nginx;

  # Virtual host submodule
  vhostOpts =
    { name, ... }:
    {
      options = {
        serverName = mkOption {
          type = types.str;
          default = name;
          description = "Server name (domain) for this virtual host.";
        };

        serverAliases = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "www.example.com" ];
          description = "Alternative server names.";
        };

        listen = mkOption {
          type = types.listOf (
            types.submodule {
              options = {
                addr = mkOption {
                  type = types.str;
                  default = "0.0.0.0";
                  description = "Listen address.";
                };
                port = mkOption {
                  type = types.port;
                  default = 80;
                  description = "Listen port.";
                };
                ssl = mkOption {
                  type = types.bool;
                  default = false;
                  description = "Whether this listener uses SSL.";
                };
              };
            }
          );
          default = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
          ];
          description = "Listen directives for this virtual host.";
        };

        root = mkOption {
          type = types.nullOr types.path;
          default = null;
          example = "/var/www/html";
          description = "Document root directory.";
        };

        index = mkOption {
          type = types.str;
          default = "index.html index.htm";
          description = "Index file(s) to serve for directory requests.";
        };

        forceSSL = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to redirect all HTTP traffic to HTTPS.";
        };

        enableACME = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to enable ACME (Let's Encrypt) for this host.";
        };

        sslCertificate = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to SSL certificate file.";
        };

        sslCertificateKey = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to SSL certificate key file.";
        };

        locations = mkOption {
          type = types.attrsOf (
            types.submodule {
              options = {
                proxyPass = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  example = "http://127.0.0.1:8080";
                  description = "Proxy requests to this backend URL.";
                };

                root = mkOption {
                  type = types.nullOr types.path;
                  default = null;
                  description = "Override root for this location.";
                };

                index = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = "Override index for this location.";
                };

                tryFiles = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  example = "$uri $uri/ =404";
                  description = "try_files directive.";
                };

                extraConfig = mkOption {
                  type = types.lines;
                  default = "";
                  description = "Additional nginx config for this location block.";
                };
              };
            }
          );
          default = { };
          description = "Location blocks for this virtual host.";
        };

        extraConfig = mkOption {
          type = types.lines;
          default = "";
          description = "Additional nginx config inside the server block.";
        };
      };
    };

  # Generate location block
  mkLocation = path: locCfg: ''
    location ${path} {
      ${optionalString (locCfg.proxyPass != null) ''
        proxy_pass ${locCfg.proxyPass};
        ${optionalString cfg.recommendedProxySettings ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
        ''}
      ''}
      ${optionalString (locCfg.root != null) "root ${locCfg.root};"}
      ${optionalString (locCfg.index != null) "index ${locCfg.index};"}
      ${optionalString (locCfg.tryFiles != null) "try_files ${locCfg.tryFiles};"}
      ${locCfg.extraConfig}
    }
  '';

  # Generate server block for a virtual host
  mkVhost = name: vhost: ''
    server {
      ${
        concatMapStringsSep "\n  " (
          l: "listen ${l.addr}:${toString l.port}${optionalString l.ssl " ssl"}"
        ) vhost.listen
      };
      server_name ${vhost.serverName} ${concatStringsSep " " vhost.serverAliases};

      ${optionalString (vhost.root != null) "root ${vhost.root};"}
      index ${vhost.index};

      ${optionalString (vhost.sslCertificate != null) "ssl_certificate ${vhost.sslCertificate};"}
      ${optionalString (
        vhost.sslCertificateKey != null
      ) "ssl_certificate_key ${vhost.sslCertificateKey};"}

      ${optionalString vhost.forceSSL ''
        if ($scheme != "https") {
          return 301 https://$server_name$request_uri;
        }
      ''}

      ${concatStringsSep "\n" (mapAttrsToList mkLocation vhost.locations)}

      ${vhost.extraConfig}
    }
  '';

  # Full nginx.conf
  nginxConf = pkgs.writeText "nginx.conf" ''
    # Generated by ekaos nginx module
    user ${cfg.user} ${cfg.group};
    worker_processes ${toString cfg.workerProcesses};
    pid /run/nginx/nginx.pid;

    events {
      worker_connections ${toString cfg.workerConnections};
    }

    http {
      include ${cfg.package}/conf/mime.types;
      default_type application/octet-stream;

      sendfile on;
      keepalive_timeout 65;

      ${optionalString cfg.recommendedGzipSettings ''
        gzip on;
        gzip_vary on;
        gzip_proxied any;
        gzip_comp_level 6;
        gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
      ''}

      ${optionalString cfg.recommendedOptimisation ''
        tcp_nopush on;
        tcp_nodelay on;
        types_hash_max_size 2048;
        server_names_hash_bucket_size 128;
      ''}

      ${optionalString cfg.recommendedTlsSettings ''
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        ssl_session_timeout 1d;
        ssl_session_cache shared:SSL:10m;
        ssl_session_tickets off;
      ''}

      access_log /var/log/nginx/access.log;
      error_log /var/log/nginx/error.log;

      ${cfg.commonHttpConfig}

      ${concatStringsSep "\n" (mapAttrsToList mkVhost cfg.virtualHosts)}

      ${cfg.httpConfig}
    }

    ${cfg.appendConfig}
  '';

in

{
  options = {
    services.nginx = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the nginx web server.";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.nginx or (throw "nginx package not available in core-pkgs");
        defaultText = literalExpression "pkgs.nginx";
        description = "The nginx package to use.";
      };

      description = mkOption {
        type = types.str;
        default = "Nginx Web Server";
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
        default = "nginx";
        description = "User to run nginx worker processes as.";
      };

      group = mkOption {
        type = types.str;
        default = "nginx";
        description = "Group to run nginx worker processes as.";
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
        type = types.attrsOf (
          types.submodule (import ../../../../services/lib/types.nix { inherit lib; }).portContract
        );
        default = { };
        description = "Port contracts for this service.";
      };

      workerProcesses = mkOption {
        type = types.either types.int (types.enum [ "auto" ]);
        default = "auto";
        description = "Number of nginx worker processes.";
      };

      workerConnections = mkOption {
        type = types.int;
        default = 1024;
        description = "Maximum number of simultaneous connections per worker.";
      };

      virtualHosts = mkOption {
        type = types.attrsOf (types.submodule vhostOpts);
        default = { };
        description = "Nginx virtual host configurations.";
        example = literalExpression ''
          {
            "example.com" = {
              root = "/var/www/example";
              locations."/" = {
                tryFiles = "$uri $uri/ =404";
              };
            };
          }
        '';
      };

      recommendedGzipSettings = mkOption {
        type = types.bool;
        default = false;
        description = "Enable recommended gzip compression settings.";
      };

      recommendedOptimisation = mkOption {
        type = types.bool;
        default = false;
        description = "Enable recommended performance optimisations.";
      };

      recommendedProxySettings = mkOption {
        type = types.bool;
        default = false;
        description = "Enable recommended proxy header settings.";
      };

      recommendedTlsSettings = mkOption {
        type = types.bool;
        default = false;
        description = "Enable recommended TLS/SSL settings.";
      };

      commonHttpConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Configuration lines added to the http block before server blocks.";
      };

      httpConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Configuration lines added to the http block after server blocks.";
      };

      appendConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Configuration lines added after the http block (for stream, mail, etc.).";
      };
    };
  };

  config = mkIf cfg.enable {
    services.nginx = {
      command = "${cfg.package}/bin/nginx";
      args = [
        "-c"
        "${nginxConf}"
        "-g"
        "daemon off;"
      ];
      restartPolicy = "always";
      systemd = {
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
      };
    };

    # Create nginx user/group
    users.users.nginx = {
      uid = 60;
      group = "nginx";
      description = "Nginx web server";
      isSystemUser = true;
      home = "/var/lib/nginx";
    };

    users.groups.nginx = {
      gid = 60;
    };

    # Port contracts for HTTP/HTTPS
    services.nginx.ports = {
      http = {
        port = 80;
        protocol = "tcp";
        transport = "tcp";
        internal = false;
        openFirewall = true;
      };
      https = {
        port = 443;
        protocol = "tcp";
        transport = "tcp";
        internal = false;
        openFirewall = true;
      };
    };

    environment.etc."nginx/nginx.conf".source = nginxConf;
    environment.systemPackages = [ cfg.package ];

    system.activationScripts.nginx = stringAfter [ "etc" "users" ] ''
      mkdir -p /var/log/nginx
      mkdir -p /var/lib/nginx
      mkdir -p /run/nginx
      chown nginx:nginx /var/log/nginx /var/lib/nginx /run/nginx
    '';
  };
}
