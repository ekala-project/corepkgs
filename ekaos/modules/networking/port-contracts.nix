# Adios port of ekaos/modules/networking/port-contracts.nix.
#
# Tree path: networking/port-contracts is parent.networking."port-contracts".
# Aggregation module: reads the whole services subtree via inputs.services
# (parent.services).
# TODO(adios-cutover): AGGREGATION GAP (load-bearing). Legacy collects port
# contracts from ALL enabled services via the global config fixpoint
# (`config.services` filtered by enable + `.ports`). Adios has no global
# fixpoint; inputs.services resolves to whatever the tree wires at
# parent.services, which cannot enumerate arbitrary service modules. Until
# the tree wires each service's ports explicitly, contracts/external/
# byHostname/acmeHosts/lookup/firewall/healthChecks may be incomplete and
# the collision assertion below may miss collisions.
# TODO(adios-cutover): contracts/external/byHostname/healthChecks/lookup
# use types.attrs instead of validated submodules; contract-shape
# validation lost. firewall.tcp/udp had no legacy default (read-only
# outputs); default [] added for adios option shape.
# TODO(adios-cutover): impl writes networking.ports.* (this module's own
# read-only outputs) and networking.extraHosts. The tree must merge impl
# outputs back (NixOS module-merge semantics); there is no in-place
# option update in adios.
{ types, ... }:

let
  filterAttrs =
    pred: set:
    builtins.listToAttrs (
      builtins.map (n: {
        name = n;
        value = set.${n};
      }) (builtins.filter (n: pred n set.${n}) (builtins.attrNames set))
    );
  mapAttrsToList = f: attrs: builtins.map (n: f n attrs.${n}) (builtins.attrNames attrs);
  unique = xs: builtins.foldl' (acc: x: if builtins.elem x acc then acc else acc ++ [ x ]) [ ] xs;
  groupBy =
    keyFn: list:
    builtins.foldl' (
      acc: x:
      let
        k = keyFn x;
      in
      acc // { ${k} = (acc.${k} or [ ]) ++ [ x ]; }
    ) { } list;

  # Shared derivation from the services subtree; used by both assertions
  # and impl (top-level let so both can share it).
  derive =
    services:
    let
      # Collect all enabled services that have port contracts
      enabledServices = filterAttrs (_: s: (s.enable or false) == true) services;

      # Flatten all port contracts into a single list with service names attached
      allContracts = builtins.concatLists (
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
      externalContracts = builtins.filter (c: !c.internal) allContracts;
      firewallContracts = builtins.filter (c: c.openFirewall) allContracts;

      # Collision detection: group by (port, protocol) key
      portKey = c: "${toString c.port}/${c.protocol}";
      grouped = groupBy portKey allContracts;
      collisions = filterAttrs (_: es: builtins.length es > 1) grouped;

      # Group external contracts by hostname for reverse proxy consumers
      withHostname = builtins.filter (c: c.hostname != null && !c.internal) allContracts;
      byHostname = groupBy (c: c.hostname) withHostname;

      # ACME hosts: hostnames that need Let's Encrypt certificates
      acmeHosts = unique (
        builtins.map (c: c.hostname) (builtins.filter (c: c.tls.acme && c.hostname != null) allContracts)
      );

      # Flat lookup table: "serviceName.portName" -> port number
      lookupTable = builtins.listToAttrs (
        builtins.map (c: {
          name = "${c.serviceName}.${c.portName}";
          value = c.port;
        }) allContracts
      );

      # Unique hostnames for /etc/hosts generation
      uniqueHostnames = unique (builtins.map (c: c.hostname) withHostname);

      # Firewall port lists
      firewallTCPPorts = unique (
        builtins.map (c: c.port) (builtins.filter (c: c.protocol == "tcp") firewallContracts)
      );
      firewallUDPPorts = unique (
        builtins.map (c: c.port) (builtins.filter (c: c.protocol == "udp") firewallContracts)
      );

      # Contracts with health checks
      healthCheckContracts = builtins.filter (c: c.healthCheck.path != null) allContracts;
    in
    {
      inherit
        allContracts
        externalContracts
        byHostname
        acmeHosts
        lookupTable
        firewallTCPPorts
        firewallUDPPorts
        healthCheckContracts
        collisions
        uniqueHostnames
        ;
    };
in

{
  options = {
    contracts = {
      type = types.listOf types.attrs;
      default = [ ];
      description = ''
        All port contracts from all enabled services.
        Each entry contains: serviceName, portName, port, protocol,
        transport, hostname, path, internal, openFirewall, tls, healthCheck.
        Read-only output; value comes from impl.
      '';
    };

    external = {
      type = types.listOf types.attrs;
      default = [ ];
      description = ''
        External-facing port contracts (internal = false).
        Read-only output; value comes from impl.
      '';
    };

    byHostname = {
      type = types.attrsOf (types.listOf types.attrs);
      default = { };
      description = ''
        Port contracts grouped by hostname.
        Reverse proxy consumers read this to auto-generate virtual host configs.
        Read-only output; value comes from impl.
      '';
    };

    acmeHosts = {
      type = types.listOf types.string;
      default = [ ];
      description = ''
        Hostnames that need ACME (Let's Encrypt) certificates.
        Derived from port contracts with tls.acme = true.
        Read-only output; value comes from impl.
      '';
    };

    lookup = {
      type = types.attrsOf types.int;
      default = { };
      example = {
        "myapp.http" = 8080;
        "myapp.metrics" = 9090;
      };
      description = ''
        Flat lookup table mapping "serviceName.portName" to port numbers.
        Useful for inter-service configuration references.
        Read-only output; value comes from impl.
      '';
    };

    firewall = {
      description = ''
        Firewall port lists derived from port contracts with
        openFirewall = true. Read-only outputs; values come from impl.
      '';
      options = {
        tcp = {
          type = types.listOf types.int;
          default = [ ];
          description = ''
            TCP ports that should be opened in the firewall.
            Derived from port contracts with openFirewall = true.
          '';
        };

        udp = {
          type = types.listOf types.int;
          default = [ ];
          description = ''
            UDP ports that should be opened in the firewall.
            Derived from port contracts with openFirewall = true.
          '';
        };
      };
    };

    healthChecks = {
      type = types.listOf types.attrs;
      default = [ ];
      description = ''
        Port contracts that have health check paths defined.
        Monitoring consumers can use this to auto-discover scrape targets.
        Read-only output; value comes from impl.
      '';
    };
  };

  inputs = {
    services.from = { root }: root.services;
  };

  assertions = [
    {
      verify = { options, inputs }: (derive inputs.services).collisions == { };
      explain =
        { options, inputs }:
        let
          collisions = (derive inputs.services).collisions;
        in
        "Port collisions: ${
          builtins.concatStringsSep "; " (
            mapAttrsToList (
              key: entries:
              "Port collision on ${key}: claimed by ${
                builtins.concatStringsSep ", " (builtins.map (e: "${e.serviceName}.${e.portName}") entries)
              }"
            ) collisions
          )
        }";
    }
  ];

  impl =
    { options, inputs }:
    let
      d = derive inputs.services;
    in
    {
      # Populate read-only options
      networking.ports = {
        contracts = d.allContracts;
        external = d.externalContracts;
        byHostname = d.byHostname;
        acmeHosts = d.acmeHosts;
        lookup = d.lookupTable;
        firewall = {
          tcp = d.firewallTCPPorts;
          udp = d.firewallUDPPorts;
        };
        healthChecks = d.healthCheckContracts;
      };
    }
    // (
      if d.uniqueHostnames != [ ] then
        {
          # Auto-generate /etc/hosts entries for declared hostnames
          networking.extraHosts = builtins.concatStringsSep "\n" (
            builtins.map (hostname: "127.0.0.1 ${hostname}") d.uniqueHostnames
          );
        }
      else
        { }
    );
}
