# Auto-configured reverse proxy from port contracts
# Reads networking.ports.byHostname and generates nginx virtual hosts
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.reverseProxy;
  portsByHost = config.networking.ports.byHostname;
  acmeHosts = config.networking.ports.acmeHosts;

  hasVhosts = portsByHost != { };

  mkUpstream =
    contract:
    let
      scheme = if contract.tls.enable then "https" else "http";
    in
    "${scheme}://127.0.0.1:${toString contract.port}";

  mkLocationBlock = contract: ''
    location ${contract.path} {
      ${
        if contract.transport == "grpc" then
          "grpc_pass grpc://127.0.0.1:${toString contract.port};"
        else
          ''
            proxy_pass ${mkUpstream contract};
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            ${optionalString (contract.transport == "http2") ''
              proxy_http_version 1.1;
              proxy_set_header Connection "";
            ''}
          ''
      }
    }
  '';

  mkServerBlock =
    hostname: contracts:
    let
      hasAcme = elem hostname acmeHosts;
      anyForceRedirect = any (c: c.tls.forceRedirect) contracts;
    in
    ''
      ${optionalString hasAcme ''
        server {
          listen ${toString cfg.httpsPort} ssl http2;
          server_name ${hostname};

          ssl_certificate /var/lib/acme/${hostname}/fullchain.pem;
          ssl_certificate_key /var/lib/acme/${hostname}/key.pem;

          ${concatMapStringsSep "\n" mkLocationBlock contracts}
        }
      ''}
      ${
        if hasAcme && anyForceRedirect then
          ''
            server {
              listen ${toString cfg.httpPort};
              server_name ${hostname};
              return 301 https://$host$request_uri;
            }
          ''
        else
          ''
            server {
              listen ${toString cfg.httpPort};
              server_name ${hostname};

              ${concatMapStringsSep "\n" mkLocationBlock contracts}
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

      ${cfg.extraHttpConfig}

      ${concatStringsSep "\n\n" (mapAttrsToList mkServerBlock portsByHost)}
    }
  '';

in

{
  options.services.reverseProxy = {
    enable = mkEnableOption "auto-configured reverse proxy from port contracts";

    httpPort = mkOption {
      type = types.port;
      default = 80;
      description = "HTTP listen port for the reverse proxy.";
    };

    httpsPort = mkOption {
      type = types.port;
      default = 443;
      description = "HTTPS listen port for the reverse proxy.";
    };

    description = mkOption {
      type = types.str;
      default = "Reverse Proxy (auto-configured)";
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
      description = "User to run service as.";
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

    extraHttpConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration to add to the http block.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = hasVhosts;
        message = "services.reverseProxy is enabled but no services have port contracts with hostnames. Add hostname to at least one service's port contract.";
      }
    ];

    services.reverseProxy = {
      command = "${pkgs.nginx}/bin/nginx";
      args = [
        "-c"
        "${nginxConf}"
      ];

      ports = {
        http = {
          port = cfg.httpPort;
          protocol = "tcp";
          transport = "http";
          openFirewall = true;
        };
      }
      // optionalAttrs (acmeHosts != [ ]) {
        https = {
          port = cfg.httpsPort;
          protocol = "tcp";
          transport = "https";
          openFirewall = true;
        };
      };

      systemd = {
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          RuntimeDirectory = "reverse-proxy";
        };
      };
    };

    # Create runtime directories
    system.activationScripts.reverseProxy = stringAfter [ "etc" ] ''
      mkdir -p /run/reverse-proxy
      mkdir -p /tmp/client_body /tmp/proxy /tmp/fastcgi /tmp/uwsgi /tmp/scgi
    '';

    environment.systemPackages = [ pkgs.nginx ];
  };
}
