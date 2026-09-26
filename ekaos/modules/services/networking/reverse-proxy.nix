# Adios port of ekaos/modules/services/networking/reverse-proxy.nix.
# TODO(adios-cutover): command/args were internal options set by the legacy
# config; they are computed in impl, not user options.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Whether to enable auto-configured reverse proxy from port contracts.";
    };

    httpPort = {
      type = types.int;
      default = 80;
      description = "HTTP listen port for the reverse proxy.";
    };

    httpsPort = {
      type = types.int;
      default = 443;
      description = "HTTPS listen port for the reverse proxy.";
    };

    description = {
      type = types.string;
      default = "Reverse Proxy (auto-configured)";
      description = "Service description.";
    };

    user = {
      type = types.string;
      default = "nginx";
      description = "User to run service as.";
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
      type = types.attrsOf types.any;
      default = { };
      description = "Port contracts for this service.";
    };

    package = {
      type = types.derivation;
      default = pkgs.nginx;
      description = "Nginx package to use for the reverse proxy.";
    };

    extraHttpConfig = {
      type = types.string;
      default = "";
      description = "Extra configuration to add to the http block.";
    };
  };

  inputs = {
    # TODO(adios-cutover): verify tree path once the networking batch lands
    # (legacy reads config.networking.ports, defined in
    # networking/port-contracts.nix).
    portContracts.from = { root }: root.networking."port-contracts";
  };

  assertions = [
    {
      verify = { options }: options.httpPort >= 0 && options.httpPort <= 65535;
      explain = { options }: "reverse proxy httpPort must be 0-65535, got ${toString options.httpPort}";
    }
    {
      verify = { options }: options.httpsPort >= 0 && options.httpsPort <= 65535;
      explain = { options }: "reverse proxy httpsPort must be 0-65535, got ${toString options.httpsPort}";
    }
    {
      verify = { options, inputs }: !options.enable || (inputs.portContracts.byHostname or { }) != { };
      explain =
        { options, inputs }:
        "services.reverseProxy is enabled but no services have port contracts with hostnames. Add hostname to at least one service's port contract.";
    }
  ];

  impl =
    { options, inputs }:
    if !options.enable then
      { }
    else
      let
        portsByHost = inputs.portContracts.byHostname or { };
        acmeHosts = inputs.portContracts.acmeHosts or [ ];

        mkUpstream =
          contract:
          let
            scheme = if (contract.tls.enable or false) then "https" else "http";
          in
          "${scheme}://127.0.0.1:${toString contract.port}";

        mkLocationBlock = contract: ''
          location ${contract.path} {
            ${
              if (contract.transport or "http") == "grpc" then
                "grpc_pass grpc://127.0.0.1:${toString contract.port};"
              else
                ''
                  proxy_pass ${mkUpstream contract};
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header X-Forwarded-Proto $scheme;
                  ${
                    if (contract.transport or "http") == "http2" then
                      ''
                        proxy_http_version 1.1;
                        proxy_set_header Connection "";
                      ''
                    else
                      ""
                  }
                ''
            }
          }
        '';

        mkServerBlock =
          hostname: contracts:
          let
            hasAcme = builtins.elem hostname acmeHosts;
            anyForceRedirect = builtins.any (c: (c.tls.forceRedirect or false)) contracts;
          in
          ''
            ${
              if hasAcme then
                ''
                  server {
                    listen ${toString options.httpsPort} ssl http2;
                    server_name ${hostname};

                    ssl_certificate /var/lib/acme/${hostname}/fullchain.pem;
                    ssl_certificate_key /var/lib/acme/${hostname}/key.pem;

                    ${builtins.concatStringsSep "\n" (builtins.map mkLocationBlock contracts)}
                  }
                ''
              else
                ""
            }
            ${
              if hasAcme && anyForceRedirect then
                ''
                  server {
                    listen ${toString options.httpPort};
                    server_name ${hostname};
                    return 301 https://$host$request_uri;
                  }
                ''
              else
                ''
                  server {
                    listen ${toString options.httpPort};
                    server_name ${hostname};

                    ${builtins.concatStringsSep "\n" (builtins.map mkLocationBlock contracts)}
                  }
                ''
            }
          '';

        nginxConf = pkgs.writeText "reverse-proxy.conf" ''
          daemon off;
          worker_processes auto;
          pid /run/reverse-proxy/nginx.pid;

          error_log stderr;

          events {
            worker_connections 1024;
          }

          http {
            access_log /dev/stdout combined;

            # Temp directories
            client_body_temp_path /tmp/client_body;
            proxy_temp_path /tmp/proxy;
            fastcgi_temp_path /tmp/fastcgi;
            uwsgi_temp_path /tmp/uwsgi;
            scgi_temp_path /tmp/scgi;

            ${options.extraHttpConfig or ""}

            ${builtins.concatStringsSep "\n\n" (
              builtins.map (hostname: mkServerBlock hostname portsByHost.${hostname}) (
                builtins.attrNames portsByHost
              )
            )}
          }
        '';
      in
      {
        services.reverseProxy = {
          inherit (options)
            enable
            description
            user
            restartPolicy
            ;
          command = "${options.package}/bin/nginx";
          args = [
            "-c"
            "${nginxConf}"
          ];
          ports =
            options.ports
            // {
              http = {
                port = options.httpPort;
                protocol = "tcp";
                transport = "http";
                openFirewall = true;
              };
            }
            // (
              if acmeHosts != [ ] then
                {
                  https = {
                    port = options.httpsPort;
                    protocol = "tcp";
                    transport = "https";
                    openFirewall = true;
                  };
                }
              else
                { }
            );
          systemd = {
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "simple";
              RuntimeDirectory = "reverse-proxy";
            };
          }
          // options.systemd;
        };

        # TODO(adios-cutover): legacy ordering (after "etc") lost; plain script.
        system.activationScripts.reverseProxy = ''
          mkdir -p /run/reverse-proxy
          mkdir -p /tmp/client_body /tmp/proxy /tmp/fastcgi /tmp/uwsgi /tmp/scgi
        '';

        environment.systemPackages = [ options.package ];
      };
}
