# Adios port of ekaos/modules/security/acme.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:
let
  # Local reimplementation of nixpkgs `lib.unique` (order-preserving dedup).
  unique = list: builtins.foldl' (acc: x: if builtins.elem x acc then acc else acc ++ [ x ]) [ ] list;
in
{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable automatic ACME certificate management.
        When enabled, certificates are automatically requested for
        hostnames declared in port contracts with tls.acme = true.
      '';
    };

    email = {
      type = types.string;
      # TODO(adios-cutover): legacy option has no default (required); no default set here.
      example = "admin@example.com";
      description = ''
        Email address for ACME account registration.
        Used for expiry notifications.
      '';
    };

    acceptTerms = {
      type = types.bool;
      default = false;
      description = ''
        Whether to accept the ACME server's terms of service.
        Must be set to true for certificate provisioning to work.
      '';
    };

    server = {
      type = types.string;
      default = "https://acme-v02.api.letsencrypt.org/directory";
      example = "https://acme-staging-v02.api.letsencrypt.org/directory";
      description = ''
        ACME server URL. Use the staging server for testing.
      '';
    };

    certDir = {
      type = types.string;
      default = "/var/lib/acme";
      description = "Base directory for certificate storage.";
    };

    renewDays = {
      type = types.int;
      default = 30;
      description = "Renew certificates when they are this many days old.";
    };

    defaultsWebroot = {
      type = types.nullOr types.string;
      default = "/var/lib/acme/acme-challenge";
      description = "Default webroot for HTTP-01 challenges.";
    };

    defaultsDnsProvider = {
      type = types.nullOr types.string;
      default = null;
      example = "cloudflare";
      description = "Default DNS provider for DNS-01 challenges.";
    };

    certs = {
      # TODO(adios-cutover): submodule validation lost (legacy `certSubmodule`
      # with extraDomainNames/webroot/dnsProvider/reloadServices/directory,
      # including its readOnly `directory` default).
      type = types.attrsOf types.attrs;
      default = { };
      description = ''
        Per-hostname certificate configuration.
        Hostnames from port contracts with tls.acme = true are
        automatically added with default settings.
      '';
    };
  };

  inputs = {
    ports.from = { root }: root.networking.ports;
    # TODO(adios-cutover): `inputs.ports.acmeHosts` assumes a
    # parent.networking.ports tree node exposes acmeHosts; verify against
    # the networking port-contract port (unresolvable from this batch).
  };

  assertions = [
    {
      verify = { options }: options.renewDays > 0;
      explain = { options }: "renewDays must be positive, got ${toString options.renewDays}";
    }
    {
      verify = { options }: (options.certs or { }) == { } || options.acceptTerms;
      explain = { options }: "security.acme.acceptTerms must be true to use ACME certificates.";
    }
    {
      verify = { options }: (options.certs or { }) == { } || (options.email or "") != "";
      explain = { options }: "security.acme.email must be set for ACME registration.";
    }
  ];

  impl =
    { options, inputs }:
    let
      acmeHosts = inputs.ports.acmeHosts or [ ];

      # Merge auto-discovered hosts with manually declared certs
      allCertHosts = unique (acmeHosts ++ (builtins.attrNames options.certs));

      # Build lego command for a given hostname
      mkLegoCertScript =
        hostname:
        let
          certCfg = options.certs.${hostname} or { };
          certDir = "${options.certDir}/${hostname}";
          extraDomains = certCfg.extraDomainNames or [ ];
          domainArgs = builtins.concatStringsSep " " (
            builtins.map (d: "-d ${d}") ([ hostname ] ++ extraDomains)
          );
          webroot = certCfg.webroot or options.defaultsWebroot;
          dnsProvider = certCfg.dnsProvider or options.defaultsDnsProvider;
        in
        ''
          # Certificate for ${hostname}
          mkdir -p ${certDir}

          if [ ! -f ${certDir}/fullchain.pem ] || \
             [ "$(${pkgs.coreutils}/bin/find ${certDir}/fullchain.pem -mtime +${toString options.renewDays})" ]; then
            echo "Requesting/renewing certificate for ${hostname}..."
            ${pkgs.lego}/bin/lego \
              --email "${options.email}" \
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
    in
    if options.enable then
      {
        # Auto-populate certs from port contracts
        security.acme.certs = builtins.listToAttrs (
          builtins.map (hostname: {
            name = hostname;
            value = { };
          }) (builtins.filter (h: !(builtins.hasAttr h options.certs)) acmeHosts)
        );

        # Install lego
        environment.systemPackages = [ pkgs.lego ];

        # Create certificate directories and request/renew certs during activation
        # TODO(adios-cutover): legacy stringAfter [ "etc" "users" ] ordering lost.
        system.activationScripts.acme = ''
          echo "ACME certificate management..."
          mkdir -p ${options.certDir}
          chmod 750 ${options.certDir}

          ${
            if (options.defaultsWebroot != null) then
              ''
                mkdir -p ${options.defaultsWebroot}
              ''
            else
              ""
          }

          ${builtins.concatStringsSep "\n" (builtins.map mkLegoCertScript allCertHosts)}
        '';
      }
    else
      { };
}
