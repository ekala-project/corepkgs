# Port contracts aggregation module
# Collects port contracts from all enabled services and provides
# derived data for consumers (reverse proxy, firewall, DNS, monitoring)
{
  config,
  lib,
  ...
}:

with lib;

let
  serviceTypes = import ../../../services/lib/types.nix { inherit lib; };

  # Collect all enabled services that have port contracts
  enabledServices = filterAttrs (_: s: (s.enable or false) == true) config.services;

  # Flatten all port contracts into a single list with service names attached
  allContracts = concatLists (
    mapAttrsToList (
      svcName: svcCfg:
      mapAttrsToList (portName: portCfg: {
        serviceName = svcName;
        inherit portName;
        inherit (portCfg)
          port
          protocol
          transport
          hostname
          path
          internal
          openFirewall
          tls
          healthCheck
          ;
      }) (svcCfg.ports or { })
    ) enabledServices
  );

  # Derived subsets
  externalContracts = filter (c: !c.internal) allContracts;
  firewallContracts = filter (c: c.openFirewall) allContracts;

  # Collision detection: group by (port, protocol) key
  portKey = c: "${toString c.port}/${c.protocol}";
  grouped = groupBy portKey allContracts;
  collisions = filterAttrs (_: es: length es > 1) grouped;

  # Group external contracts by hostname for reverse proxy consumers
  withHostname = filter (c: c.hostname != null && !c.internal) allContracts;
  byHostname = groupBy (c: c.hostname) withHostname;

  # ACME hosts: hostnames that need Let's Encrypt certificates
  acmeHosts = unique (
    map (c: c.hostname) (filter (c: c.tls.acme && c.hostname != null) allContracts)
  );

  # Flat lookup table: "serviceName.portName" -> port number
  lookupTable = listToAttrs (
    map (c: nameValuePair "${c.serviceName}.${c.portName}" c.port) allContracts
  );

  # Unique hostnames for /etc/hosts generation
  uniqueHostnames = unique (map (c: c.hostname) withHostname);

  # Firewall port lists
  firewallTCPPorts = unique (map (c: c.port) (filter (c: c.protocol == "tcp") firewallContracts));
  firewallUDPPorts = unique (map (c: c.port) (filter (c: c.protocol == "udp") firewallContracts));

  # Contracts with health checks
  healthCheckContracts = filter (c: c.healthCheck.path != null) allContracts;

in

{
  options.networking.ports = {
    contracts = mkOption {
      type = types.listOf (types.attrsOf types.unspecified);
      internal = true;
      default = [ ];
      description = ''
        All port contracts from all enabled services.
        Each entry contains: serviceName, portName, port, protocol,
        transport, hostname, path, internal, openFirewall, tls, healthCheck.
      '';
    };

    external = mkOption {
      type = types.listOf (types.attrsOf types.unspecified);
      internal = true;
      default = [ ];
      description = ''
        External-facing port contracts (internal = false).
      '';
    };

    byHostname = mkOption {
      type = types.attrsOf (types.listOf (types.attrsOf types.unspecified));
      internal = true;
      default = { };
      description = ''
        Port contracts grouped by hostname.
        Reverse proxy consumers read this to auto-generate virtual host configs.
      '';
    };

    acmeHosts = mkOption {
      type = types.listOf types.str;
      internal = true;
      default = [ ];
      description = ''
        Hostnames that need ACME (Let's Encrypt) certificates.
        Derived from port contracts with tls.acme = true.
      '';
    };

    lookup = mkOption {
      type = types.attrsOf types.port;
      internal = true;
      default = { };
      description = ''
        Flat lookup table mapping "serviceName.portName" to port numbers.
        Useful for inter-service configuration references.
      '';
      example = literalExpression ''
        {
          "myapp.http" = 8080;
          "myapp.metrics" = 9090;
        }
      '';
    };

    firewall = {
      tcp = mkOption {
        type = types.listOf types.port;
        description = ''
          TCP ports that should be opened in the firewall.
          Derived from port contracts with openFirewall = true.
        '';
      };

      udp = mkOption {
        type = types.listOf types.port;
        description = ''
          UDP ports that should be opened in the firewall.
          Derived from port contracts with openFirewall = true.
        '';
      };
    };

    healthChecks = mkOption {
      type = types.listOf (types.attrsOf types.unspecified);
      internal = true;
      default = [ ];
      description = ''
        Port contracts that have health check paths defined.
        Monitoring consumers can use this to auto-discover scrape targets.
      '';
    };
  };

  config = {
    # Populate read-only options
    networking.ports = {
      contracts = allContracts;
      external = externalContracts;
      inherit byHostname acmeHosts;
      lookup = lookupTable;
      firewall = {
        tcp = firewallTCPPorts;
        udp = firewallUDPPorts;
      };
      healthChecks = healthCheckContracts;
    };

    # Port collision assertions
    assertions = mapAttrsToList (key: entries: {
      assertion = false;
      message = "Port collision on ${key}: claimed by ${
        concatMapStringsSep ", " (e: "${e.serviceName}.${e.portName}") entries
      }";
    }) collisions;

    # Auto-generate /etc/hosts entries for declared hostnames
    networking.extraHosts = mkIf (uniqueHostnames != [ ]) (
      concatMapStringsSep "\n" (hostname: "127.0.0.1 ${hostname}") uniqueHostnames
    );
  };
}
