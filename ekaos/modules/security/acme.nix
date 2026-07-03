# ACME certificate management module
# Auto-provisions Let's Encrypt certificates for hostnames declared
# in port contracts with tls.acme = true
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.security.acme;
  acmeHosts = config.networking.ports.acmeHosts or [ ];

  # Merge auto-discovered hosts with manually declared certs
  allCertHosts = unique (acmeHosts ++ (attrNames cfg.certs));

  # Build lego command for a given hostname
  mkLegoCertScript =
    hostname:
    let
      certCfg = cfg.certs.${hostname} or { };
      certDir = "${cfg.certDir}/${hostname}";
      extraDomains = certCfg.extraDomainNames or [ ];
      domainArgs = concatMapStringsSep " " (d: "-d ${d}") ([ hostname ] ++ extraDomains);
      webroot = certCfg.webroot or cfg.defaults.webroot;
      dnsProvider = certCfg.dnsProvider or cfg.defaults.dnsProvider;
    in
    ''
      # Certificate for ${hostname}
      mkdir -p ${certDir}

      if [ ! -f ${certDir}/fullchain.pem ] || \
         [ "$(${pkgs.coreutils}/bin/find ${certDir}/fullchain.pem -mtime +${toString cfg.renewDays})" ]; then
        echo "Requesting/renewing certificate for ${hostname}..."
        ${pkgs.lego}/bin/lego \
          --email "${cfg.email}" \
          --accept-tos \
          ${domainArgs} \
          --path ${certDir} \
          ${
            if dnsProvider != null then
              "--dns ${dnsProvider}"
            else if webroot != null then
              "--http --http.webroot ${webroot}"
            else
              "--http"
          } \
          run || echo "Warning: certificate request for ${hostname} failed"
      else
        echo "Certificate for ${hostname} is still valid"
      fi
    '';

  certSubmodule = {
    options = {
      extraDomainNames = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Additional domain names (SANs) for this certificate.";
      };

      webroot = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Webroot path for HTTP-01 challenge. Overrides defaults.";
      };

      dnsProvider = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "cloudflare";
        description = "DNS provider for DNS-01 challenge. Overrides defaults.";
      };

      reloadServices = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "nginx" ];
        description = "Services to reload after certificate renewal.";
      };

      directory = mkOption {
        type = types.str;
        readOnly = true;
        default = "${cfg.certDir}/certificates";
        description = "Directory containing the certificate files.";
      };
    };
  };

in

{
  options.security.acme = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable automatic ACME certificate management.
        When enabled, certificates are automatically requested for
        hostnames declared in port contracts with tls.acme = true.
      '';
    };

    email = mkOption {
      type = types.str;
      example = "admin@example.com";
      description = ''
        Email address for ACME account registration.
        Used for expiry notifications.
      '';
    };

    acceptTerms = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to accept the ACME server's terms of service.
        Must be set to true for certificate provisioning to work.
      '';
    };

    server = mkOption {
      type = types.str;
      default = "https://acme-v02.api.letsencrypt.org/directory";
      example = "https://acme-staging-v02.api.letsencrypt.org/directory";
      description = ''
        ACME server URL. Use the staging server for testing.
      '';
    };

    certDir = mkOption {
      type = types.str;
      default = "/var/lib/acme";
      description = "Base directory for certificate storage.";
    };

    renewDays = mkOption {
      type = types.ints.positive;
      default = 30;
      description = "Renew certificates when they are this many days old.";
    };

    defaults = {
      webroot = mkOption {
        type = types.nullOr types.str;
        default = "/var/lib/acme/acme-challenge";
        description = "Default webroot for HTTP-01 challenges.";
      };

      dnsProvider = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "cloudflare";
        description = "Default DNS provider for DNS-01 challenges.";
      };
    };

    certs = mkOption {
      type = types.attrsOf (types.submodule certSubmodule);
      default = { };
      description = ''
        Per-hostname certificate configuration.
        Hostnames from port contracts with tls.acme = true are
        automatically added with default settings.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.acceptTerms;
        message = "security.acme.acceptTerms must be true to use ACME certificates.";
      }
      {
        assertion = cfg.email != "";
        message = "security.acme.email must be set for ACME registration.";
      }
    ];

    # Auto-populate certs from port contracts
    security.acme.certs = listToAttrs (
      map (hostname: nameValuePair hostname { }) (filter (h: !(hasAttr h cfg.certs)) acmeHosts)
    );

    # Install lego
    environment.systemPackages = [ pkgs.lego ];

    # Create certificate directories and request/renew certs during activation
    system.activationScripts.acme = stringAfter [ "etc" "users" ] ''
      echo "ACME certificate management..."
      mkdir -p ${cfg.certDir}
      chmod 750 ${cfg.certDir}

      ${optionalString (cfg.defaults.webroot != null) ''
        mkdir -p ${cfg.defaults.webroot}
      ''}

      ${concatMapStringsSep "\n" mkLegoCertScript allCertHosts}
    '';
  };
}
