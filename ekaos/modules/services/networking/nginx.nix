# Adios port of ekaos/modules/services/networking/nginx.nix.
# TODO(adios-cutover): command/args were internal options set by the legacy
# config; they are computed in impl, not user options.
# TODO(adios-cutover): ports used the shared portContract submodule type
# (imported from services/lib/types.nix); submodule validation lost.
# TODO(adios-cutover): virtualHosts used attrsOf (submodule ...) with
# per-host/per-location/per-listener defaults; submodule validation lost and
# defaults are re-applied via `or` fallbacks in impl.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Whether to enable the nginx web server.";
    };

    package = {
      type = types.derivation;
      default = pkgs.nginx or (throw "nginx package not available in core-pkgs");
      description = "The nginx package to use.";
    };

    description = {
      type = types.string;
      default = "Nginx Web Server";
      description = "Service description.";
    };

    user = {
      type = types.string;
      default = "nginx";
      description = "User to run nginx worker processes as.";
    };

    group = {
      type = types.string;
      default = "nginx";
      description = "Group to run nginx worker processes as.";
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

    workerProcesses = {
      type = types.union [
        types.int
        (types.enum "workerProcesses" [ "auto" ])
      ];
      default = "auto";
      description = "Number of nginx worker processes.";
    };

    workerConnections = {
      type = types.int;
      default = 1024;
      description = "Maximum number of simultaneous connections per worker.";
    };

    virtualHosts = {
      type = types.attrsOf types.attrs;
      default = { };
      description = "Nginx virtual host configurations.";
    };

    recommendedGzipSettings = {
      type = types.bool;
      default = false;
      description = "Enable recommended gzip compression settings.";
    };

    recommendedOptimisation = {
      type = types.bool;
      default = false;
      description = "Enable recommended performance optimisations.";
    };

    recommendedProxySettings = {
      type = types.bool;
      default = false;
      description = "Enable recommended proxy header settings.";
    };

    recommendedTlsSettings = {
      type = types.bool;
      default = false;
      description = "Enable recommended TLS/SSL settings.";
    };

    commonHttpConfig = {
      type = types.string;
      default = "";
      description = "Configuration lines added to the http block before server blocks.";
    };

    httpConfig = {
      type = types.string;
      default = "";
      description = "Configuration lines added to the http block after server blocks.";
    };

    appendConfig = {
      type = types.string;
      default = "";
      description = "Configuration lines added after the http block (for stream, mail, etc.).";
    };
  };

  impl =
    { options, ... }:
    if !options.enable then
      { }
    else
      let
        vhosts = options.virtualHosts or { };

        mkLocation = path: locCfg: ''
          location ${path} {
            ${
              if (locCfg.proxyPass or null) != null then
                ''
                  proxy_pass ${locCfg.proxyPass};
                  ${
                    if (options.recommendedProxySettings or false) then
                      ''
                        proxy_set_header Host $host;
                        proxy_set_header X-Real-IP $remote_addr;
                        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                        proxy_set_header X-Forwarded-Proto $scheme;
                      ''
                    else
                      ""
                  }
                ''
              else
                ""
            }
            ${if (locCfg.root or null) != null then "root ${locCfg.root};" else ""}
            ${if (locCfg.index or null) != null then "index ${locCfg.index};" else ""}
            ${if (locCfg.tryFiles or null) != null then "try_files ${locCfg.tryFiles};" else ""}
            ${locCfg.extraConfig or ""}
          }
        '';

        mkVhost = name: vhost: ''
          server {
            ${
              builtins.concatStringsSep "\n  " (
                builtins.map
                  (
                    l:
                    "listen ${l.addr or "0.0.0.0"}:${toString (l.port or 80)}${if (l.ssl or false) then " ssl" else ""}"
                  )
                  (
                    vhost.listen or [
                      {
                        addr = "0.0.0.0";
                        port = 80;
                      }
                    ]
                  )
              )
            };
            server_name ${vhost.serverName or name} ${
              builtins.concatStringsSep " " (vhost.serverAliases or [ ])
            };

            ${if (vhost.root or null) != null then "root ${vhost.root};" else ""}
            index ${vhost.index or "index.html index.htm"};

            ${
              if (vhost.sslCertificate or null) != null then "ssl_certificate ${vhost.sslCertificate};" else ""
            }
            ${
              if (vhost.sslCertificateKey or null) != null then
                "ssl_certificate_key ${vhost.sslCertificateKey};"
              else
                ""
            }

            ${
              if (vhost.forceSSL or false) then
                ''
                  if ($scheme != "https") {
                    return 301 https://$server_name$request_uri;
                  }
                ''
              else
                ""
            }

            ${builtins.concatStringsSep "\n" (
              builtins.map (path: mkLocation path (vhost.locations or { }).${path}) (
                builtins.attrNames (vhost.locations or { })
              )
            )}

            ${vhost.extraConfig or ""}
          }
        '';

        nginxConf = pkgs.writeText "nginx.conf" ''
          # Generated by ekaos nginx module
          user ${options.user} ${options.group};
          worker_processes ${toString options.workerProcesses};
          pid /run/nginx/nginx.pid;

          events {
            worker_connections ${toString (options.workerConnections or 1024)};
          }

          http {
            include ${options.package}/conf/mime.types;
            default_type application/octet-stream;

            sendfile on;
            keepalive_timeout 65;

            ${
              if (options.recommendedGzipSettings or false) then
                ''
                  gzip on;
                  gzip_vary on;
                  gzip_proxied any;
                  gzip_comp_level 6;
                  gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
                ''
              else
                ""
            }

            ${
              if (options.recommendedOptimisation or false) then
                ''
                  tcp_nopush on;
                  tcp_nodelay on;
                  types_hash_max_size 2048;
                  server_names_hash_bucket_size 128;
                ''
              else
                ""
            }

            ${
              if (options.recommendedTlsSettings or false) then
                ''
                  ssl_protocols TLSv1.2 TLSv1.3;
                  ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
                  ssl_prefer_server_ciphers off;
                  ssl_session_timeout 1d;
                  ssl_session_cache shared:SSL:10m;
                  ssl_session_tickets off;
                ''
              else
                ""
            }

            access_log /var/log/nginx/access.log;
            error_log /var/log/nginx/error.log;

            ${options.commonHttpConfig or ""}

            ${builtins.concatStringsSep "\n" (
              builtins.map (name: mkVhost name vhosts.${name}) (builtins.attrNames vhosts)
            )}

            ${options.httpConfig or ""}
          }

          ${options.appendConfig or ""}
        '';
      in
      {
        services.nginx = {
          inherit (options)
            enable
            description
            user
            group
            restartPolicy
            ;
          command = "${options.package}/bin/nginx";
          args = [
            "-c"
            "${nginxConf}"
            "-g"
            "daemon off;"
          ];
          ports = options.ports // {
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
          systemd = {
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
          }
          // options.systemd;
        };

        users.users.nginx = {
          uid = 60;
          group = "nginx";
          description = "Nginx web server";
          isSystemUser = true;
          homeDirectory = "/var/lib/nginx";
        };

        users.groups.nginx = {
          gid = 60;
        };

        environment.etc."nginx/nginx.conf".source = nginxConf;
        environment.systemPackages = [ options.package ];

        # TODO(adios-cutover): legacy ordering (after "etc" "users") lost; plain script.
        system.activationScripts.nginx = ''
          mkdir -p /var/log/nginx
          mkdir -p /var/lib/nginx
          mkdir -p /run/nginx
          chown nginx:nginx /var/log/nginx /var/lib/nginx /run/nginx
        '';
      };
}
