# Adios port of ekaos/modules/services/stubs.nix.
#
# Service stubs for services referenced by other modules but not yet fully
# implemented. The legacy module declares options only (no config section),
# so impl returns an empty fragment; the stub values live under this node's
# own options.
# TODO(adios-cutover): legacy option namespaces were services.hydra,
# services.grafana and services.nix-serve; here they are grouped as
# hydra/grafana/nixServe sub-options of this node. Consumers must read them
# via inputs from parent.services.stubs until real modules land.
{ types, ... }:

{
  options = {
    hydra = {
      options = {
        enable = {
          type = types.bool;
          default = false;
          description = "Whether to enable Hydra CI. (Stub — not yet implemented in core-pkgs.)";
        };

        port = {
          type = types.int;
          default = 3000;
          description = "Port for the Hydra web interface.";
        };

        hydraURL = {
          type = types.string;
          default = "http://localhost:3000";
          description = "The base URL of the Hydra instance.";
        };

        notificationSender = {
          type = types.string;
          default = "hydra@localhost";
          description = "Email address used for Hydra notifications.";
        };

        buildMachinesFiles = {
          type = types.listOf types.pathLike;
          default = [ ];
          description = "Paths to build machine files for Hydra.";
        };

        useSubstitutes = {
          type = types.bool;
          default = true;
          description = "Whether Hydra builds should use binary substitutes.";
        };

        package = {
          type = types.nullOr types.derivation;
          default = null;
          description = "The Hydra package to use.";
        };
      };
      description = "Hydra CI server stub options.";
    };

    grafana = {
      options = {
        enable = {
          type = types.bool;
          default = false;
          description = "Whether to enable Grafana. (Stub — not yet implemented in core-pkgs.)";
        };

        settings = {
          type = types.attrsOf (types.attrsOf types.any);
          default = { };
          description = ''
            Grafana settings (INI sections as nested attrs).
          '';
        };
      };
      description = "Grafana stub options.";
    };

    nixServe = {
      options = {
        enable = {
          type = types.bool;
          default = false;
          description = "Whether to enable nix-serve. (Stub — not yet implemented in core-pkgs.)";
        };

        secretKeyFile = {
          type = types.nullOr types.pathLike;
          default = null;
          description = "Path to the secret signing key for nix-serve.";
        };

        port = {
          type = types.int;
          default = 5000;
          description = "Port for nix-serve to listen on.";
        };
      };
      description = "nix-serve stub options.";
    };
  };

  assertions = [
    {
      verify = { options }: options.hydra.port >= 0 && options.hydra.port <= 65535;
      explain = { options }: "hydra port must be 0-65535, got ${toString options.hydra.port}";
    }
    {
      verify = { options }: options.nixServe.port >= 0 && options.nixServe.port <= 65535;
      explain = { options }: "nix-serve port must be 0-65535, got ${toString options.nixServe.port}";
    }
  ];

  # No config in legacy — these are stubs only.
  impl = { ... }: { };
}
